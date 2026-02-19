import os
import ../color

proc listup*() =
  log_info("updating package list")
  let exit = execShellCmd("curl -s -L -o /etc/car/packagelist https://github.com/redroselinux/car3-pkgs/raw/refs/heads/main/README")
  if exit != 0:
    log_error("failed to update package list")
    quit()
  else:
    log_ok("package list updated")
