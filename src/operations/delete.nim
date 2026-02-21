import os
import strutils
import sequtils
import times
import ../color

proc delete*(packages: seq[string]) =
  let start = getTime()
  let reproPath = "/etc/repro.car"

  var reproLines = readFile(reproPath).splitLines()

  for pkg in packages:
    let savePath = "/etc/car/saves/" & pkg

    if fileExists(savePath):
      let savedFiles = readFile(savePath).splitLines()

      for line in savedFiles:
        let target = line.strip()

        if target == "" or target == "car":
          continue

        if fileExists(target):
          try:
            removeFile(target)
          except OSError:
            log_error("permission denied or error deleting: " & target)
        else:
          log_info("file already gone: " & target)

      removeFile(savePath)
    else:
      log_error("no tracking file found for: " & pkg)

    reproLines.keepItIf(not it.startsWith(pkg & "="))

  writeFile(reproPath, reproLines.join("\n"))

  let elapsed = getTime() - start
  log_ok("process complete in " & $elapsed.inMilliseconds & " ms")
