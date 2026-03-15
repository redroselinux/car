import os
import strutils
import ../color

proc listup*() =
  log_info("updating package list")
  var mirror = ""
  try:
    mirror = readFile("/etc/car/mirror").strip()
  except:
    log_error("no mirror is set. did you run 'car init'?")
    quit()
  let exit = execShellCmd("curl -s -L -o /etc/car/packagelist " & mirror)
  if exit != 0:
    log_error("failed to update package list")
    quit()
  if execShellCmd("cat /etc/car_propiertary.lock 2>/dev/null") == 0:
    # propiertary enabled
    log_info("updating propriertary repo")
    let exit = execShellCmd("curl -s -L https://github.com/redroselinux/car-propiertary-repo/raw/refs/heads/main/README >> /etc/car/packagelist")
    if exit != 0:
      log_error("failed to update package list")
      quit()
  log_ok("package list updated")
  quit() # i have no clue why didnt this quit by itself
