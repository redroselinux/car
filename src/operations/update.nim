import tables
import color
import listup
import install
import delete
import strutils
import sequtils

proc update*() =
  listup()

  let packagelist = readFile("/etc/car/packagelist")
  let repro = readFile("/etc/repro.car")

  let lines = packagelist.splitLines()
  let header = lines[0]

  # a situation where the packagelist does not
  # include the update header; should only happen
  # before the first friday after the addition of it
  if not header.startsWith("UPDATE:"):
    log_warn "No update available"
    log_info "Run news-reader to see what caused this; this is an edge case."
    return

  let parts = header.split(":", 4)
  if parts.len < 5:
    log_error "invalid update header"
    return

  var oldUpdateInfo: string
  try:
    oldUpdateInfo = readFile("/etc/car/update")
  except:
    oldUpdateInfo = ""
  let updateInfo = parts[1].strip()
  if (oldUpdateInfo == updateInfo):
    log_ok "No new update available"
    log_info "Delete /etc/car/update to force an update"
    return
  let updateAddPkg = parts[2].strip().split(",").mapIt(it.strip()).filterIt(it.len > 0)
  let updateDelPkg = parts[3].strip().split(",").mapIt(it.strip()).filterIt(it.len > 0)
  let updateShowMsg = parts[4].strip()

  log_info updateInfo
  if updateShowMsg.len > 0:
    log_info updateShowMsg

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

  log_info "Merging installed, to update, to install, and to delete packages"
  var updatable: seq[string] = @[]
  for pkg, installedVersion in installed.pairs:
    if pkg in repoVersions:
      if pkg in updateDelPkg: continue
      if pkg in updateAddPkg: continue
      let repoVersion = repoVersions[pkg]
      if repoVersion != installedVersion:
        updatable.add(pkg)

  let packages_word = if updatable.len == 1:
                        "package"
                      else:
                        "packages"
  let adding_word = if updateAddPkg.len == 1:
                        "package"
                      else:
                        "packages"
  let deleting_word = if updateDelPkg.len == 1:
                        "package"
                      else:
                        "packages"

  if updateAddPkg.len > 0:
    log_info("\e[92mAdding\e[0m " & $updateAddPkg.len & " " & adding_word & ":")
    echo("    " & updateAddPkg.join(", "))
  if updateDelPkg.len > 0:
    log_info("\e[91mRemoving\e[0m " & $updateDelPkg.len & " " & deleting_word & ":")
    echo("    " & updateDelPkg.join(", "))
  if updatable.len > 0:
    log_info("\e[94mUpdating\e[0m " & $updatable.len & " " & packages_word & ":")
    echo("    " & updatable.join(", "))
  stdout.write "  Continue? [Y/n] "
  let confirm = readLine(stdin).toLowerAscii()
  if confirm.startsWith("y") or confirm == "":
    discard
  else:
    quit(130)

  writeFile("/etc/car/update", updateInfo)

  var reproLines = readFile("/etc/repro.car").splitLines()
  reproLines.keepItIf(it.contains("=") and it.split("=")[0].strip() notin updatable)
  writeFile("/etc/repro.car", reproLines.join("\n"))

  install(updateAddPkg, force=true)
  for pkg in updateAddPkg:
    writeFile("/etc/car/saves/" & pkg & "-update", "Package was installed by maintainer-issued update.")
  delete(updateDelPkg)
  install(updatable, force=true)

  log_warn("Finished system upgrade - you should reboot your system right now")
