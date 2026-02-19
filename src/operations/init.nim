import os
import ../color

import listup

proc isInited*(): bool =
  dirExists("/etc/car")

proc createConfig() =
  createDir("/etc/car")
  createDir("/etc/car/saves")
  writeFile("/etc/repro.car", "")
  writeFile("/etc/car/packagelist", "")
  listup()

proc init*(force: bool) =
  log_info("creating car configs")

  if not force:
    if isInited():
      log_error("already initialized. to reinit:")
      log_info("> car init --force")
      quit()
    createConfig()
  else:
    log_warn("forced re-init")
    createConfig()
