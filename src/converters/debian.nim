import ../color
import os
import strutils

proc convertDebPackage*(input: string): string =
  # clean
  discard execShellCmd("rm -rf /tmp/car_convert_deb")

  log_info "extracting " & input
  var ainput = absolutePath(input)
  createDir("/tmp/car_convert_deb")
  setCurrentDir("/tmp/car_convert_deb")
  if execShellCmd("ar -x " & ainput) != 0:
    log_error("failed to unpack")

  log_info "extracting /tmp/car_convert_deb/data.tar.xz"
  createDir("/tmp/car_convert_deb/package")
  if execShellCmd("tar -xf /tmp/car_convert_deb/data.tar.xz -C /tmp/car_convert_deb/package --strip-components=1") != 0:
    log_error("failed to extract data.tar.xz")

  log_info "extracting /tmp/car_convert_deb/control.tar.xz"
  createDir("/tmp/car_convert_deb/info")
  if execShellCmd("tar -xf /tmp/car_convert_deb/control.tar.xz -C /tmp/car_convert_deb/info --strip-components=1") != 0:
    log_error("failed to extract control.tar.xz")

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

  writeFile("/tmp/car_convert_deb/package/car", "exec printf \"\e[1m\e[93mwarning\e[0m: this package is converted from a .deb package\\n\"\nversion " & version & "\n" & depslines)

  log_info "creating a car package"
  if execShellCmd("tar -I \"zstd -T0\" -cf /var/cache/" & displayName & ".tar.zst -C /tmp/car_convert_deb package") != 0:
    log_error "failed to create the package"
    quit(1)

  log_ok "finished converting package"

  return "/var/cache/" & displayName & ".tar.zst"
