import os
import strutils
import sequtils
import color

proc delete*(packages: seq[string]) =
  var reproLines = readFile("/etc/repro.car").splitLines()
  var skipped_packages: seq[string]
  for pkg in packages:
    if not reproLines.anyIt(it.startsWith(pkg & "=")):
      log_error("Package not installed: " & pkg & " - skipping")
      skipped_packages.add(pkg)
      continue

    try:
      let redrose_strap = readFile("/etc/redrose-strap")
      if redrose_strap.splitLines().anyIt(it.strip() == pkg):
        log_warn(pkg & " came preinstalled with Redrose Linux. Removing it may break your system!")
        stdout.write "  Continue? [y/N] "
        let confirm = readLine(stdin).toLowerAscii()
        if not confirm.startsWith("y"):
          log_info("Skipping " & pkg)
          skipped_packages.add(pkg)
          continue
    except:
      discard

    if fileExists("/etc/car/saves/" & pkg):
      let savedFiles = readFile("/etc/car/saves/" & pkg).splitLines()
      for line in savedFiles:
        let target = "/" & line.strip()
        if target == "/" or target == "/car":
          continue
        if fileExists(target):
          try:
            removeFile(target)
          except OSError:
            log_error("Permission denied or error deleting: " & target)
        else:
          log_warn("File missing: " & target)
      removeFile("/etc/car/saves/" & pkg)
      removeFile("/etc/car/saves/" & pkg & "-update")
    else:
      log_warn("No tracking file found for: " & pkg)

    reproLines.keepItIf(not it.startsWith(pkg & "="))
    log_ok("Deleted " & pkg)

  writeFile("/etc/repro.car", reproLines.join("\n"))
