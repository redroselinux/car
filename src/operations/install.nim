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
  if file == "" or not fileExists(file): return

  let start = getTime()

  let cleanName = displayName.stripSuffix(".tar.zst").stripSuffix(".tar")

  let exit = execShellCmd("tar -I zstd -xf " & file & " -C / --strip-components=1")
  if exit != 0:
    log_error("failed to unpack " & file)
    return

  var version = "unknown"
  if fileExists("/car"):
    try:
      for line in readFile("/car").splitLines():
        if line.startsWith("version "):
          version = line.split(" ")[1]
          break
    except IOError: discard

  let packages_config = open("/etc/repro.car", fmAppend)
  packages_config.writeLine(cleanName & "=" & version)
  packages_config.close()

  discard execShellCmd("mkdir -p /etc/car/saves")
  discard execShellCmd(
    "tar --zstd -tf " & file & " | sed 's|^[^/]*/||' | grep -v '/$' | grep -v '^car$' | grep -v '^$' | sed 's|^|/|' > /etc/car/saves/" & cleanName
  )

  let elapsed = getTime() - start
  log_ok("installed " & cleanName & " (" & version & ") successfully in " & $elapsed.inMilliseconds & " ms")

proc install*(packages: seq[string]) =
  if not isInited():
    log_error("car is not initialized")
    quit()

  var local_packages: seq[string]
  var remote_packages: seq[string]

  for pkg in packages:
    if pkg == "" or pkg == "[]": continue
    if pkg.endsWith(".tar.zst"):
      local_packages.add(pkg)
    else:
      remote_packages.add("/tmp/" & pkg & ".tar.zst")

  for i in local_packages:
    let displayName = i.splitFile.name.stripSuffix(".tar.zst")
    install_backend(i, displayName)

    if fileExists("/car"):
      let carLines = readFile("/car").splitLines()
      for line in carLines:
        if line.startsWith("dep "):
          install(@[line.split(" ")[1]])
      removeFile("/car")

  for i in remote_packages:
    if not fileExists(i): continue
    let displayName = i.splitFile.name.stripSuffix(".tar.zst")

    install_backend(i, displayName)

    if fileExists("/car"):
      let carLines = readFile("/car").splitLines()
      for line in carLines:
        if line.startsWith("dep "):
          install(@[line.split(" ")[1]])
      removeFile("/car")
