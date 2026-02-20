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
  log_pick("mirror (pick one close to you)")
  let mirrors = ["https://github.com/redroselinux/car3-pkgs/raw/refs/heads/main/README"]
  var counter = 1
  for i in mirrors:
    log_option("[" & $counter & "]: " & i)
    counter += 1
  stdout.write "> "
  var mirror = readLine(stdin)
  if mirror == "":
    mirror = "1"
    log_warn("using default mirror")
  writeFile("/etc/car/mirror", mirrors[parseInt(mirror) - 1])
  writeFile("/etc/car/packagelist", "")
  listup()

proc init*(force: bool) =
  log_info("creating car configs")

  if not force:
    if isInited():
      log_error("already initialized. to reinit:")
      log_error("> car init --force")
      quit()
    createConfig()
  else:
    log_warn("forced re-init")
    createConfig()
