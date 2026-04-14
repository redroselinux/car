import os
import strutils
import ../color
import init
import times

let packagelist = readFile("/etc/car/packagelist")
var repro_car = readFile("/etc/repro.car")

proc stripSuffix(s: string, suffix: string): string =
  if s.endsWith suffix:
    return s[0 .. s.len - suffix.len - 1]
  else:
    return s

proc install_backend(file: string, displayName: string) =
  # 0 - nothing failed
  # 1 - something failed
  # if everything fails, the program quits
  var fail_level = 0

  let start = getTime()

  if execShellCmd(
    "tar -I \"zstd -T0\" -xvf " & file & " -C / --strip-components=1 " &
    "| sed 's|^[^/]*/||' | grep -v '/$' > /etc/car/saves/" & displayName
  ) != 0:
    log_error("failed to unpack " & file)
    quit(1)

  let manifest = readFile "/car"
  var version = "NONE"
  for line in manifest.split("\n"):
    if line.startsWith("version "):
      version = line.split(" ")[1]
    elif line.startsWith("exec"):
      if execShellCmd(line) != 0:
        log_warn("a script failed to execute")
        fail_level = 1

  let packages_config = open("/etc/repro.car", fmAppend)
  packages_config.writeLine(displayName & "=" & version)
  packages_config.close()
  repro_car = readFile("/etc/repro.car") # reload

  var elapsed = getTime() - start
  var fail_level_word = "succesfully"
  if fail_level == 1:
    fail_level_word = "\e[1m\e[93mpartially succesfully\e[0m"
  if version == "NONE" or version == "":
    log_ok(
      "installed " & displayName & " " & fail_level_word & " in " & $elapsed.inMilliseconds & " ms"
    )
  else:
    log_ok(
      "installed " & displayName & " (" & version & ") " & fail_level_word & " in " & $elapsed.inMilliseconds & " ms"
    )

var installedLegacy: seq[string] = @[]
proc legacy_install(package: string) =
  if package in installedLegacy:
    return
  installedLegacy.add(package)

  log_info("installing legacy package " & package)

  log_info("attempting to fetch from car-coreutils-repo")
  discard execShellCmd(
    "curl -sL -w '%{http_code}' -o /tmp/install_script_ " &
    "https://github.com/redroselinux/car-coreutils-repo/raw/refs/heads/main/" &
    package & "/install_script > /tmp/http_status"
  )

  if readFile("/tmp/http_status").strip() == "200":
    copyFile("/tmp/install_script_", "/tmp/install_script.py")
  else:
    log_info("attempting to fetch from car-binary-storage")
    discard execShellCmd(
      "curl -sL -w '%{http_code}' -o /tmp/install_script_ " &
      "https://github.com/redroselinux/car-binary-storage/raw/refs/heads/main/" &
      package & "/install_script > /tmp/http_status"
    )
    if readFile("/tmp/http_status").strip() == "200":
      copyFile("/tmp/install_script_", "/tmp/install_script.py")
    else:
      log_error("package " & package & " does not exist")
      quit(1)

  log_info("acquired install_script")
  log_warn("using legacy packages is not reccomended.")
  log_warn("it may not work or even worse it may break your system in some packages!")
  stdout.write "         continue? [y/N] "

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
          log_info("installing dependencies of " & package)
          for dep in cleaned.split(","):
            let d = dep.strip()
            if d.len == 0: continue
            if d == package: continue
            legacy_install(d)

  if execShellCmd(
    "python3 -c \"import runpy; ns = runpy.run_path('/tmp/install_script.py'); " &
    "[(f:=ns.get(n)) and callable(f) and f() for n in ('beforeinst','deps','install','postinst')]\""
  ) != 0:
    log_error("running install_script failed.")
    log_warn("it is possible that the package was still installed succesfully. READ THE LOGS!")

  log_warn("this package is not tracked by car. try using old car for better results. this is also not recommended.")

proc install*(packages: seq[string], force=false) =
  if not isInited():
    log_error("car is not initialized")
    log_error("run 'car init' to initialize car")
    quit(2)

  var local_packages: seq[string]
  var remote_packages: seq[string]
  var already_installed_packages: seq[string]

  let downloadStart = getTime()

  for pkg in packages:
    if pkg.startsWith("legacy::"):
      legacy_install(pkg.split("::")[1])
      continue
    if pkg == "[]":
      continue
    if pkg & "=" in repro_car:
      if not force:
        log_info("package already installed: " & pkg)
        already_installed_packages.add(pkg)
        continue
    var download_disable = false
    if fileExists("/var/cache/" & pkg & ".tar.zst"):
      if not force:
        log_info("package cached: " & pkg)
        download_disable = true
    if pkg.endsWith ".tar.zst":
      local_packages.add(pkg)
      continue
    var found = false

    if not download_disable:
      for line in packagelist.split("\n"):
        if line.startswith(pkg & " - "):
          found = true
          let download = line.split(" - ")[1]
          log_info("downloading " & download)
          let exit = execShellCmd("curl -# -L -o /var/cache/" & pkg & ".tar.zst " & download)
          if exit != 0:
            log_error("failed to download package " & pkg & " (exit " & $exit & ")")
            quit(1)
          break
    else:
      found = true

    if not found:
      log_error("package " & pkg & " not found - skipping")
    else:
      remote_packages.add "/var/cache/" & pkg & ".tar.zst"

  let downloadTime = getTime() - downloadStart
  let downloadSeconds = float(downloadTime.inMilliseconds) / 1000.0
  if downloadSeconds > 0.05:
    log_ok("downloads took " & $downloadSeconds & " seconds")

  var deps: seq[string]

  for i in local_packages:
    if i in already_installed_packages:
      log_info "package already installed: " & i
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
  for i in remote_packages:
    if i in already_installed_packages:
      log_info "package already installed: " & i
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
