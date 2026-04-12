import os
import strutils
import sequtils
import times
import ../color

proc delete*(packages: seq[string]) =
  let start = getTime()
  var reproLines = readFile("/etc/repro.car").splitLines()

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
              log_error("permission denied or error deleting: " & target)
          else:
            log_warn("file missing: " & target)

        removeFile("/etc/car/saves/" & pkg)
      else:
        log_warn("no tracking file found for: " & pkg)
        return

      reproLines.keepItIf(not it.startsWith(pkg & "="))
      log_ok("deleted " & pkg)
    else:
      log_error("package not found: " & pkg & " - skipping")
      continue

  writeFile("/etc/repro.car", reproLines.join("\n"))

  let elapsed = getTime() - start
  log_done("complete in " & $elapsed.inMilliseconds & " ms")
