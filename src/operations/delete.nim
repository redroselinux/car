import os
import strutils
import sequtils
import times
import ../color

proc delete*(packages: seq[string]) =
  var reproLines = readFile("/etc/repro.car").splitLines()
  var skipped_packages: seq[string]

  for pkg in packages:
    if pkg & "=" in reproLines.join():
      if fileExists("/etc/car/saves/" & pkg):
        let savedFiles = readFile("/etc/car/saves/" & pkg).splitLines()

        for line in savedFiles:
          let target = "/" & line.strip()
          # when running from like ./car this would remove the current build sooo
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
      else:
        log_warn("No tracking file found for: " & pkg)
        continue

      reproLines.keepItIf(not it.startsWith(pkg & "="))
      log_ok("Deleted " & pkg)
    else:
      log_error("Package not found: " & pkg & " - skipping")
      skipped_packages.add(pkg)
      continue

  writeFile("/etc/repro.car", reproLines.join("\n"))
