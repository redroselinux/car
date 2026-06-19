import os
import strutils
import color
import fsck_symlink_attacks

proc listup*() =
  log_info("Updating package list")
  var mirrors = ""
  try:
    mirrors = readFile("/etc/car/mirror").strip()
  except:
    log_error("No mirror is set. Did you run 'car init'?")
    quit()
  var mirrorParts: seq[string] = @[]
  var cur = ""
  for i, c in mirrors:
    if c == ':' and i + 2 < mirrors.len and mirrors[i+1] == '/' and mirrors[i+2] == '/':
      cur.add(c)
    elif c == ':':
      mirrorParts.add(cur)
      cur = ""
    else:
      cur.add(c)
  if cur != "": mirrorParts.add(cur)
  for mir in mirrorParts:
    let mirror = mir.strip()
    fsckSymlinkAttacks("/etc/car/packagelist")
    log_info mirror
    if execShellCmd("curl -s -L " & mirror & " >> /etc/car/packagelist") != 0:
      log_error("Failed to update package list")
      quit()
  # yes, this is a typo.
  # however, the file is used quite often, so it was decided to keep it as it is.
  # https://docs.redroselinux.org/#/fhs?id=car_propiertarylock
  if fileExists("/etc/car_propiertary.lock"):
    # propriertary enabled; legacy thing, but it is kept bceause the docs, installer etc
    log_info("Updating propriertary repo")
    fsckSymlinkAttacks("/etc/car/packagelist")
    if execShellCmd("curl -s -L https://github.com/redroselinux/car-propiertary-repo/raw/refs/heads/main/README >> /etc/car/packagelist") != 0:
      log_error("Failed to update package list")
    log_done "Package list updated"

proc addRepo*(repo: string) =
  let mirror = readFile("/etc/car/mirror").strip()
  let repo_config = open("/etc/car/mirror", fmAppend)
  if mirror[^1] == ':':
    repo_config.write(repo)
  else:
    repo_config.write(":" & repo)
  log_done "Added " & repo
  repo_config.close()
