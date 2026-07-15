import os
import repo
import color
import strutils
import fsck_symlink_attacks

proc isInited*(): bool =
  dirExists("/etc/car")

proc writeMirror() =
  let repos = getRepos()
  var mirrors: seq[string]

  var currentRepo = ""
  var choices: seq[seq[string]]

  for repo in repos:
    if repo[3] != currentRepo:
      if currentRepo != "":
        stdout.write("> ")
        var choice = readLine(stdin)

        if choice == "":
          choice = if currentRepo == "proprietary": "0" else: "1"

        if not (currentRepo == "proprietary" and choice == "0"):
          mirrors.add(choices[parseInt(choice) - 1][1])

      currentRepo = repo[3]
      choices.setLen(0)
      log_pick("Which provider for " & currentRepo & " do you want?")

      if currentRepo == "proprietary":
        log_option("[0]: None")

    choices.add(repo)
    log_option("[" & $choices.len & "]: " & repo[0])

  if choices.len != 0:
    stdout.write("> ")
    var choice = readLine(stdin)

    if choice == "":
      choice = if currentRepo == "proprietary": "0" else: "1"

    if not (currentRepo == "proprietary" and choice == "0"):
      mirrors.add(choices[parseInt(choice) - 1][1])

  fsckSymlinkAttacks("/etc/car/mirror")
  writeFile("/etc/car/mirror", mirrors.join(":"))

proc createConfig() =
  fsckSymlinkAttacks("/etc/car")
  createDir("/etc/car")

  fsckSymlinkAttacks("/etc/car/saves")
  createDir("/etc/car/saves")

  try:
    discard readFile("/etc/repro.car") # if suceeds, we are on a redrose system
  except:
    # not a redrose system
    fsckSymlinkAttacks("/etc/repro.car")
    writeFile("/etc/repro.car", "")

  writeMirror()

  fsckSymlinkAttacks("/etc/car/packagelist")
  writeFile("/etc/car/packagelist", "")

  listup()
  quit(0)

proc init*(force: bool) =
  if not force:
    if isInited():
      log_error("Already initialized. To reinitialize (not recommended):")
      echo("  car init --force")
      quit()

    log_info("Creating car configs")
    createConfig()
  else:
    log_warn("Forced re-init")
    createConfig()

proc redroseInstallerCarInit*() =
  createConfig()
  writeMirror()
