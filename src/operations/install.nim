import os
import strutils
import ../color
import init

proc stripSuffix(s: string, suffix: string): string =
  if s.endsWith(suffix):
    return s[0 .. s.len - suffix.len - 1]
  else:
    return s

proc install_backend(file: string, displayName: string) =
  let exit = execShellCmd("tar -I zstd -xf " & file & " -C / --strip-components=1")
  if exit != 0:
    log_error("failed to unpack " & file)
    quit()

  let manifest = readFile("/car")
  var version = ""
  for line in manifest.split("\n"):
    if line.startsWith("version "):
      version = line.split(" ")[1]

  let packages_config = open("/etc/repro.car", fmAppend)
  packages_config.writeLine(displayName & "=" & version)
  packages_config.close()

  log_ok("installed " & file.stripSuffix(".tar.zst") & " (" & version & ") successfully")

proc install*(packages: seq[string]) =
  if not isInited():
    log_error("car is not initialized")
    log_error("run 'car init' to initialize car")
    quit()

  var local_packages: seq[string]
  var remote_packages: seq[string]

  log_info("installing " & packages.join(", "))
  var packagelist = readFile("/etc/car/packagelist")

  for pkg in packages:
    var download_disable = false
    if fileExists("/tmp/" & pkg & ".tar.zst"):
      log_info("package already downloaded: " & pkg)
      download_disable = true
    if pkg.endsWith(".tar.zst"):
      local_packages.add(pkg)
      continue
    if not download_disable:
      for line in packagelist.split("\n"):
        if line.startswith(pkg):
          let download = line.split(" - ")[1]
          log_info("downloading " & download)
          let exit = execShellCmd("curl -s -L -o /tmp/" & pkg & ".tar.zst " & download)
          if exit != 0:
            log_error("failed to download package " & pkg & " (exit " & $exit & ")")
            quit()
    remote_packages.add("/tmp/" & pkg & ".tar.zst")

  for i in local_packages:
    var displayName = i
    if "/" in displayName:
      displayName = displayName[displayName.rfind("/") + 1 .. ^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    log_info("installing local package " & i)
    install_backend(i, displayName)

  for i in remote_packages:
    var displayName = i
    if displayName.startsWith("/tmp/"):
      displayName = displayName[5..^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    log_info("installing remote package " & displayName)
    install_backend(i, displayName)
