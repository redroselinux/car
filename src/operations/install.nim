import os
import strutils
import osproc
import color
import init
import times
import fsck_symlink_attacks

import ../converters/debian

var deps: seq[string]
var already_installed_packages: seq[string]
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

proc install_backend(file: string, displayNamec: string) =
  var displayName = displayNamec
  # 0 - nothing failed
  # 1 - something failed
  # if everything fails, the program quits
  var fail_level = 0

  let start = getTime()

  fsckSymlinkAttacks("/car")
  # package is arch, and arch packages dont need strip
  let stripComponents = if file.endsWith(".pkg.tar.zst"): "" else: "--strip-components=1"
  if execShellCmd(
    "tar -I \"zstd -T0\" -xvf " & file & " -C / " & stripComponents &
    "| sed 's|^[^/]*/||' | grep -v '/$' > /etc/car/saves/" & displayName
  ) != 0:
    log_error("Failed to unpack " & file)
    log_info("Maybe try running 'car clearcache'?")
    quit(1)
  var manifest: string
  try:
    manifest = readFile "/car"
  except:
    # maybe this is an arch package?
    try:
      manifest = "##ARCHPKG##\n" & readFile "/.PKGINFO"
      fsckSymlinkAttacks("/.PKGINFO"); removeFile("/.PKGINFO")
      fsckSymlinkAttacks("/.MTREE"); removeFile("/.MTREE")
      fsckSymlinkAttacks("/.BUILDINFO"); removeFile("/.BUILDINFO")
    except:
      log_error "Failed to read manifest."
      quit 1
  var version = "NONE"
  var arch_package = false
  for line in manifest.split("\n"):
    if line == "##ARCHPKG##":
      log_warn "Installing an Arch Linux package"
      arch_package = true
    if not arch_package:
      if not (" " in line):
        continue
      let line_split_1 = line.split(" ")[1]
      if line.startsWith("version "):
        version = line_split_1
      elif line.startsWith("exec"):
        if execShellCmd(line) != 0:
          log_warn("A script failed to execute: " & line.replace("exec ", ""))
          fail_level = 1
      elif line.startsWith("dep"):
        if line_split_1 in already_installed_packages:
          continue
        deps.add(line_split_1)
    else:
      if (not ("=" in line)) or line[0] == '#':
        continue
      let key = line.split("=")[0].strip
      let value = line.split("=")[1].strip
      if key == "pkgver":
        version = value
      if key == "pkgname":
        # we found the name, now we move the /etc/car/saves file
        let displayNameNew = value
        moveFile("/etc/car/saves/" & displayName, "/etc/car/saves/" & displayNameNew)
        displayName = displayNameNew
      if key == "depend":
        deps.add(value)
      if key == "optdepend":
        log_option "Optional dependency: " & value

  fsckSymlinkAttacks("/car")
  removeFile("/car")

  fsckSymlinkAttacks("/etc/repro.car")
  let packages_config = open("/etc/repro.car", fmAppend)
  packages_config.writeLine(displayName & "=" & version)
  packages_config.close()
  repro_car = readFile("/etc/repro.car") # reload

  var elapsed = getTime() - start
  var fail_level_word = "sucesfully"
  if fail_level == 1:
    fail_level_word = "\e[1m\e[93mpartially sucesfully\e[0m"
  if version == "NONE" or version == "":
    log_ok(
      "Installed " & displayName & " " & fail_level_word & " in " & $elapsed.inMilliseconds & " ms"
    )
  else:
    log_ok(
      "Installed " & displayName & " (" & version & ") " & fail_level_word & " in " & $elapsed.inMilliseconds & " ms"
    )

var installedLegacy: seq[string] = @[]
proc legacy_install(package: string) =
  if package in installedLegacy:
    return
  installedLegacy.add(package)

  log_info("Attempting to fetch from car-coreutils-repo")
  fsckSymlinkAttacks("/tmp/http_status")
  fsckSymlinkAttacks("/tmp/install_script_")
  discard execShellCmd(
    "curl -sL -w '%{http_code}' -o /tmp/install_script_ " &
    "https://github.com/redroselinux/car-coreutils-repo/raw/refs/heads/main/" &
    package & "/install_script > /tmp/http_status"
  )

  if readFile("/tmp/http_status").strip() == "200":
    fsckSymlinkAttacks("/tmp/install_script.py")
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

proc install*(packages: seq[string], force=false, running_as_dep=false) =
  if not isInited():
    log_error("Car is not initialized")
    log_error("Run 'car init' to initialize car")
    quit(2)
  let packagelist = readFile("/etc/car/packagelist")

  var local_packages: seq[string]
  var deb_convert_packages: seq[string]
  var remote_packages: seq[string]
  var remote_downloads: seq[(string, string, string)]

  for pkg in packages:
    # the system is upgrading and this is what brake does h
    if fileExists("/etc/car/saves/" & pkg & "-brake"):
      log_option "Skipping " & pkg & ": package is braked"
      continue
    if pkg.startsWith("legacy::"):
      legacy_install(pkg.split("::")[1])
      continue
    if pkg == "[]":
      continue
    if pkg & "=" in repro_car:
      if not force:
        log_option "Skipping " & pkg & ": package is already installed"
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
        fsckSymlinkAttacks(cachePath)
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

  for i in local_packages:
    if i in already_installed_packages:
      if not running_as_dep:
        log_option "Skipping " & i & ": package is already installed"
      continue
    var displayName = i
    if "/" in displayName:
      displayName = displayName[displayName.rfind("/") + 1 .. ^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    install_backend i, displayName
  for i in deb_convert_packages:
    install @[convertDebPackage(i)]

  for i in remote_packages:
    if i in already_installed_packages:
      if not running_as_dep:
        log_option "Skipping " & i & ": package is already installed"
      continue
    var displayName = i
    if displayName.startsWith("/var/cache/"):
      displayName = displayName[11..^1]
    displayName = stripSuffix(displayName, ".tar.zst")
    install_backend i, displayName

    install(deps, running_as_dep=true)
