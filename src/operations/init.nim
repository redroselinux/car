import os
import ../color
import strutils

import listup

proc isInited*(): bool =
  dirExists("/etc/car")

proc createConfig() =
  createDir("/etc/car")
  createDir("/etc/car/saves")
  writeFile("/etc/repro.car", "")
  log_pick("Mirror (pick one close to you) [default 1]")
  let mirrors = ["https://github.com/redroselinux/car3-pkgs/raw/refs/heads/main/README"]
  var counter = 1
  for i in mirrors:
    log_option("[" & $counter & "]: " & i)
    counter += 1
  stdout.write "> "
  var mirror = readLine(stdin)
  if mirror == "":
    mirror = "1"
  writeFile("/etc/car/mirror", mirrors[parseInt(mirror) - 1])
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
