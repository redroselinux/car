import os
import strutils
import osproc
import ../color
import init
import times
import posix
import streams

import ../converters/debian

var repro_car: string
try:
  repro_car = readFile("/etc/repro.car")
except IOError:
  # car is not inited, we can put an example value since the file is unreachable for now
  repro_car = ""

proc stripSuffix(s: string, suffix: string): string =
  if s.endsWith suffix:
    return s[0 .. s.len - suffix.len - 1]
  else:
    return s

proc parseTarOctal(s: string): int =
  for c in s:
    if c < '0' or c > '7': break
    result = result * 8 + (ord(c) - ord('0'))

proc install_backend(file: string, displayName: string) =
  # 0 - nothing failed
  # 1 - something failed
  # if everything fails, the program quits
  var fail_level = 0
  let start = getTime()

  let zstd = startProcess("zstd", args = ["-dc", "-T0", file], options = {poUsePath})
  let stream = zstd.outputStream
  let mf = open("/etc/car/saves/" & displayName, fmWrite)
  var longName = ""

  while true:
    var hdr = newString(512)
    if stream.readData(addr hdr[0], 512) < 512: break
    if hdr[0] == '\0': break

    let typeFlag = hdr[156]
    let rawName = if longName != "": longName
                  else: hdr[0..99].strip(chars = {'\0', ' '})
    longName = ""

    let size = parseTarOctal(hdr[124..135])
    let blocks = (size + 511) div 512
    var data = newString(blocks * 512)
    if blocks > 0: discard stream.readData(addr data[0], blocks * 512)

    if typeFlag == 'L':
      longName = data[0..<size].strip(chars = {'\0'})
      continue

    var name = rawName
    let slash = name.find('/')
    if slash >= 0: name = name[slash + 1 .. ^1]
    if name == "": continue
    let dest = "/" & name
    if typeFlag == '5' or name.endsWith("/"):
      createDir(dest)
      continue

    mf.writeLine(name)
    createDir(dest.parentDir)

    if typeFlag == '2':
      let target = hdr[157..256].strip(chars = {'\0', ' '})
      discard tryRemoveFile(dest)
      createSymlink(target, dest)
    else:
      writeFile(dest, data[0..<size])
      discard posix.chmod(dest.cstring, Mode(parseTarOctal(hdr[100..107])))

  mf.close()
  discard zstd.waitForExit()
  zstd.close()

  let carManifest = readFile("/car")
  var version = "NONE"
  for line in carManifest.split("\n"):
    if line.startsWith("version "):
      version = line.split(" ")[1]
    elif line.startsWith("exec"):
      if execShellCmd(line) != 0:
        log_warn("A script failed to execute: " & line.replace("exec ", ""))
        fail_level = 1

  let packages_config = open("/etc/repro.car", fmAppend)
  packages_config.writeLine(displayName & "=" & version)
  packages_config.close()
  repro_car = readFile("/etc/repro.car")

  let elapsed = getTime() - start
  let fw = if fail_level == 1: "\e[1m\e[93mpartially sucesfully\e[0m" else: "sucesfully"
  let us = elapsed.inMicroseconds
  let timeStr = if us < 1_000_000:
                  formatFloat(us.float / 1000.0, ffDecimal, 1) & " ms"
                else:
                  formatFloat(us.float / 1_000_000.0, ffDecimal, 1) & " s"

  if version == "NONE" or version == "":
    log_ok("Installed " & displayName & " " & fw & " in " & timeStr)
  else:
    log_ok("Installed " & displayName & " (" & version & ") " & fw & " in " & timeStr)

var installedLegacy: seq[string] = @[]
proc legacy_install(package: string) =
  if package in installedLegacy:
    return
  installedLegacy.add(package)

  log_info("Attempting to fetch from car-coreutils-repo")
  discard execShellCmd(
    "curl -sL -w '%{http_code}' -o /tmp/install_script_ " &
    "https://github.com/redroselinux/car-coreutils-repo/raw/refs/heads/main/" &
    package & "/install_script > /tmp/http_status"
  )

  if readFile("/tmp/http_status").strip() == "200":
    copyFile("/tmp/install_script_", "/tmp/install_script.py")
  else:
    log_info("\e[1A\r\e[1m\e[94m→\e[0m Attempting to fetch from car-binary-storage    ")
    discard execShellCmd(
      "curl -sL -w '%{http_code}' -o /tmp/install_script_ " &
      "https://github.com/redroselinux/car-binary-storage/raw/refs/heads/main/" &
      package & "/install_script > /tmp/http_status"
    )
    if readFile("/tmp/http_status").strip() == "200":
      copyFile("/tmp/install_script_", "/tmp/install_script.py")
    else:
      log_error("Package " & package & " does not exist")
      quit(1)

  log_info("\e[1A\r\e[1m\e[94m→\e[0m Acquired install_script")
  log_warn("Using legacy packages is not recomended. It may not work and it may break your system!")
  stdout.write "         Continue? [y/N] "

  let confirm = readLine(stdin)
  if not confirm.toLowerAscii().startsWith("y"):
    quit(130)

  let install_script = readFile("/tmp/install_script.py")

  for line in install_script.splitLines():
    if line.strip().startsWith("car_deps"):
      let parts = line.split("=", 1)
      if parts.len == 2:
        let cleaned = parts[1]
          .replace("[", "")
          .replace("]", "")
          .replace("\"", "")
          .replace("'", "")
          .strip()
        if cleaned.len > 0:
          log_info("Installing dependencies of " & package)
          for dep in cleaned.split(","):
            let d = dep.strip()
            if d.len == 0: continue
            if d == package: continue
            legacy_install(d)
  if execShellCmd(
    "python3 -c \"import runpy; ns = runpy.run_path('/tmp/install_script.py'); " &
    "[(f:=ns.get(n)) and callable(f) and f() for n in ('beforeinst','deps','install','postinst')]\""
  ) != 0:
    log_error("Running install_script failed.")
    log_warn("It is possible that the package was still installed succesfully. READ THE LOGS!")

  log_warn("This package is not tracked by car. Try using old car for better results, which is also not recommended.")

proc install*(packages: seq[string], force=false) =
  if not isInited():
    log_error("Car is not initialized")
    log_error("Run 'car init' to initialize car")
    quit(2)
  let packagelist = readFile("/etc/car/packagelist")

  var local_packages: seq[string]
  var deb_convert_packages: seq[string]
  var remote_packages: seq[string]
  var already_installed_packages: seq[string]
  var remote_downloads: seq[(string, string, string)]

  for pkg in packages:
    if pkg.startsWith("legacy::"):
      legacy_install(pkg.split("::")[1])
      continue
    if pkg == "[]":
      continue
    if pkg & "=" in repro_car:
      if not force:
        log_info("Package already installed: " & pkg)
        already_installed_packages.add(pkg)
        continue
    var download_disable = false
    if fileExists("/var/cache/" & pkg & ".tar.zst"):
      if not force:
        download_disable = true
    if pkg.endsWith ".tar.zst":
      local_packages.add(pkg)
      continue
    if pkg.endsWith ".deb":
      deb_convert_packages.add(pkg)
      continue
    let cachePath = "/var/cache/" & pkg & ".tar.zst"
    if not download_disable:
      var download = ""
      for line in packagelist.splitLines():
        if line.len == 0 or line.startsWith("version"):
          continue
        if line.startsWith(pkg & " - "):
          let parts = line.split(" - ", 1)
          if parts.len == 2:
            download = parts[1].strip()
            break
      if download.len == 0:
        log_error("Package " & pkg & " not found - skipping")
        continue
      remote_downloads.add((pkg, download, cachePath))
    remote_packages.add cachePath

  if remote_downloads.len > 0:
    var jobs = 6
    let jobsRaw = getEnv("CAR_DOWNLOAD_JOBS", "6")
    try:
      let parsed = parseInt(jobsRaw)
      if parsed > 0:
        jobs = parsed
    except ValueError:
      discard
    var startIdx = 0
    var downloadLogLines = 0
    while startIdx < remote_downloads.len:
      let endIdx = min(startIdx + jobs - 1, remote_downloads.high)
      var workers: seq[(string, string, Process)]
      for idx in startIdx..endIdx:
        let (pkg, download, cachePath) = remote_downloads[idx]
        log_info("Downloading " & pkg)
        downloadLogLines += 1
        let downloadProc = startProcess(
          "curl",
          args = @["-s", "-L", "-o", cachePath, download],
          options = {poUsePath}
        )
        workers.add((pkg, cachePath, downloadProc))

      for worker in workers:
        let exitCode = waitForExit(worker[2])
        close(worker[2])
        if exitCode != 0:
          log_error("Failed to download package " & worker[0] & " (exit " & $exitCode & ")")
          quit(1)

      startIdx = endIdx + 1
    for _ in 0..<downloadLogLines:
      stdout.write("\e[1A\r\e[J")
    flushFile(stdout)

  var deps: seq[string]

  for i in local_packages:
    if i in already_installed_packages:
      log_info "Package already installed: " & i
      continue
    var displayName = i
    if "/" in displayName:
      displayName = displayName[displayName.rfind("/") + 1 .. ^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    install_backend i, displayName
    let car = readFile "/car"
    for i in car.splitLines():
      if i.startsWith("dep"):
        if i.split(" ")[1] in already_installed_packages:
          continue
        deps.add(i.split(" ")[1])
  for i in deb_convert_packages:
    install @[convertDebPackage(i)]

  for i in remote_packages:
    if i in already_installed_packages:
      log_info "Package already installed: " & i
      continue
    var displayName = i
    if displayName.startsWith("/var/cache/"):
      displayName = displayName[11..^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    install_backend i, displayName
    let car = readFile "/car"
    for i in car.splitLines():
      if i.startsWith("dep"):
        if i.split(" ")[1] in already_installed_packages:
          continue
        deps.add(i.split(" ")[1])
    removeFile("/car")

    install deps
