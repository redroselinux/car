import os
import strutils
import ../color
import init
import times

proc stripSuffix(s: string, suffix: string): string =
  if s.endsWith(suffix):
    return s[0 .. s.len - suffix.len - 1]
  else:
    return s

proc install_backend(file: string, displayName: string) =
  let start = getTime()

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

  discard execShellCmd(
    "mkdir -p /etc/car/saves && " &
    "tar --zstd -tf " & file &
    " | sed 's|^[^/]*/||' | grep -v '/$' > /etc/car/saves/" & displayName
  )

  let elapsed = getTime() - start
  log_ok(
    "installed " & displayName & " (" & version & ") successfully in " & $elapsed.inMilliseconds & " ms"
  )

proc install*(packages: seq[string]) =
  if not isInited():
    log_error("car is not initialized")
    log_error("run 'car init' to initialize car")
    quit()

  var local_packages: seq[string]
  var remote_packages: seq[string]

  let downloadStart = getTime()

  var packagelist = readFile("/etc/car/packagelist")

  for pkg in packages:
    var download_disable = false
    if fileExists("/tmp/" & pkg & ".tar.zst"):
      log_info("package cached: " & pkg)
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

  let downloadTime = getTime() - downloadStart
  let downloadSeconds = float(downloadTime.inMilliseconds) / 1000.0
  if downloadSeconds != float(0):
    log_ok("downloads took " & $downloadSeconds & " seconds")

  for i in local_packages:
    var displayName = i
    if "/" in displayName:
      displayName = displayName[displayName.rfind("/") + 1 .. ^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    install_backend(i, displayName)
    let car = readFile("/car")
    for i in car.splitLines():
      if i.startsWith("dep"):
        let dep = i.split(" ")[1]
        install(@[dep])
  discard execShellCmd("rm -f /car")

  for i in remote_packages:
    var displayName = i
    if displayName.startsWith("/tmp/"):
      displayName = displayName[5..^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    install_backend(i, displayName)
    let car = readFile("/car")
    for i in car.splitLines():
      if i.startsWith("dep"):
        let dep = i.split(" ")[1]
        install(@[dep])
    discard execShellCmd("rm -f /car")
