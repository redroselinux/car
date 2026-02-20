import os
import ../color

proc listup*() =
  log_info("updating package list")
  var mirror = ""
  try:
    mirror = readFile("/etc/car/mirror")
  except:
    log_error("no mirror is set. did you run 'car init'?")
    quit()
  let exit = execShellCmd("curl -s -L -o /etc/car/packagelist " & mirror)
  if exit != 0:
    log_error("failed to update package list")
    quit()
  else:
    log_ok("package list updated")
    quit() # i have no clue why didnt this quit by itself
