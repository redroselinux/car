import os
import strutils
import color
import fsck_symlink_attacks

proc listup*() =
  # TODO: custom repos

  log_info("Updating package list")
  var mirror = ""
  try:
    mirror = readFile("/etc/car/mirror").strip()
  except:
    log_error("No mirror is set. Did you run 'car init'?")
    quit()
  fsckSymlinkAttacks("/etc/car/packagelist")
  if execShellCmd("curl -s -L -o /etc/car/packagelist " & mirror) != 0:
    log_error("Failed to update package list")
    quit()
  if fileExists("/etc/car_propiertary.lock"):
    # propiertary enabled
    log_info("Updating propriertary repo")
    fsckSymlinkAttacks("/etc/car/packagelist")
    if execShellCmd("curl -s -L https://github.com/redroselinux/car-propiertary-repo/raw/refs/heads/main/README >> /etc/car/packagelist") != 0:
      log_error("Failed to update package list")
      quit()
  stdout.write("\e[A\r\e[1m\e[92m✔\e[0m Package list updated         \n")
