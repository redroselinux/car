import color
import os
import strutils
import fsck_symlink_attacks

proc convertDebPackage*(input: string): string =
  # clean
  fsckSymlinkAttacks("/tmp/car_convert_deb")
  discard execShellCmd("rm -rf /tmp/car_convert_deb")

  log_info "Extracting " & input
  var ainput = absolutePath(input)
  createDir("/tmp/car_convert_deb")
  setCurrentDir("/tmp/car_convert_deb")
  if execShellCmd("ar -x " & ainput) != 0:
    log_error("Failed to unpack")

  log_info "Extracting /tmp/car_convert_deb/data.tar.*"
  createDir("/tmp/car_convert_deb/package")
  fsckSymlinkAttacks("/tmp/car_convert_deb/data.tar.gz")
  fsckSymlinkAttacks("/tmp/car_convert_deb/data.tar.xz")
  if execShellCmd("tar -xf /tmp/car_convert_deb/data.tar.* -C /tmp/car_convert_deb/package --strip-components=1") != 0:
    log_error("Failed to extract data.tar.*")

  log_info "Extracting /tmp/car_convert_deb/control.tar.*"
  createDir("/tmp/car_convert_deb/info")
  fsckSymlinkAttacks("/tmp/car_convert_deb/control.tar.gz")
  fsckSymlinkAttacks("/tmp/car_convert_deb/control.tar.xz")
  if execShellCmd("tar -xf /tmp/car_convert_deb/control.tar.* -C /tmp/car_convert_deb/info --strip-components=1") != 0:
    log_error("Failed to extract control.tar.*")

  var displayName = "Unknown"
  var version = "Unknown"
  var deps: seq[string]
  for i in readFile("/tmp/car_convert_deb/info/control").splitLines():
    if i.startsWith("Package: "):
      displayName = i.split(": ")[1].strip()
    if i.startsWith("Version: "):
      version = i.split(": ")[1]
    if i.startsWith("Depends:"):
      # everything after "Depends:"
      for dep in i.split(": ")[1].split(", "): # format is Depends: dep (ver), dep
        if "|" in dep: # sometimes theres a | in there - this cleanly splits them across diff deps
          for subdep in dep.split("|"):
            deps.add(subdep.split("(")[0])
          continue
        deps.add(dep.split("(")[0]) # everything before "(": Depends: package (version)
  var depslines = ""
  for i in deps:
    depslines = depslines & "dep " & i.strip() & "\n"

  fsckSymlinkAttacks("/tmp/car_convert_deb/package/car")
  writeFile("/tmp/car_convert_deb/package/car", "exec printf \"\e[1m\e[93m⚠\e[0m This package is converted from a .deb package\\n\"\nversion " & version & "\n" & depslines)

  log_info "Creating a car package at /var/cache/" & displayName & ".tar.zst"
  fsckSymlinkAttacks("/var/cache/" & displayName & ".tar.zst")
  if execShellCmd("tar -I \"zstd -T0\" -cf /var/cache/" & displayName & ".tar.zst -C /tmp/car_convert_deb package") != 0:
    log_error "Failed to create the package"
    quit(1)

  return "/var/cache/" & displayName & ".tar.zst"
