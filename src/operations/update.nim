import tables
import ../color
import listup
import install
import strutils
import sequtils

proc update*() =
  listup()

  let packagelist = readFile("/etc/car/packagelist")
  let repro = readFile("/etc/repro.car")

  var installed = initTable[string,string]()
  for line in repro.splitLines():
    if line.contains("="):
      let parts = line.split("=")
      installed[parts[0].strip()] = parts[1].strip()

  var repoVersions = initTable[string,string]()
  var pkgName = ""
  for line in packagelist.splitLines():
    let l = line.strip()
    if l.len == 0:
      continue
    if l.contains(" - "):
      pkgName = l.split(" - ")[0].strip()
    elif l.startsWith("version") and pkgName.len > 0:
      let version = l.split(' ')[^1].strip()
      repoVersions[pkgName] = version

  var updatable: seq[string] = @[]
  for pkg, installedVersion in installed.pairs:
    if pkg in repoVersions:
      let repoVersion = repoVersions[pkg]
      if repoVersion != installedVersion:
        updatable.add(pkg)

  if updatable.len == 0:
    log_ok "System is already up to date"
    quit(0)
  
  let packages_word = if updatable.len == 1:
                        "package"
                      else:
                        "packages"
  log_info("Updating " & $updatable.len & " " & packages_word & ":")
  echo("    " & updatable.join(", "))
  stdout.write "  Continue? [Y/n] "
  let confirm = readLine(stdin).toLowerAscii()
  if confirm.startsWith("y") or confirm == "":
    discard
  else:
    quit(130)

  var reproLines = readFile("/etc/repro.car").splitLines()
  reproLines.keepItIf(it.split("=")[0] notin updatable)
  writeFile("/etc/repro.car", reproLines.join("\n"))

  install(updatable, force=true)

  log_done("Finished system upgrade")
  log_warn("You should reboot your system right now")
