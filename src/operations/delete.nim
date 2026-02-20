import os
import strutils
import ../color
import times

proc delete*(packages: seq[string]) =
  let start = getTime()

  for pkg in packages:
    try:
      let saved = readFile("/etc/car/saves/" & pkg)
      for line in saved.split("\n"):
        if line == "car":
          continue
        discard execShellCmd("rm -f " & line)
    except:
      log_error("failed to delete package " & pkg)
    discard execShellCmd("rm -f /etc/car/saves/" & pkg)

  let elapsed = getTime() - start
  log_ok("deleted all selected packages in " & $(elapsed.inMilliseconds) & " ms")
