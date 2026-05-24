import color
import os

proc brakePackages*(packages: seq[string]) =
  for i in packages:
    if not fileExists("/etc/car/saves/" & i):
      log_error "Package " & i & " is not installed."
      quit(1)
    if fileExists("/etc/car/saves/" & i & "-brake"):
      log_error "Package " & i & " is is already braked."
      quit(1)
    writeFile("/etc/car/saves/" & i & "-brake", "This package is braked; it does not recieve updates.")
    log_ok "Braked " & i

proc releasePackages*(packages: seq[string]) =
  for i in packages:
    if not fileExists("/etc/car/saves/" & i):
      log_error "Package " & i & " is not installed."
      quit(1)
    if not fileExists("/etc/car/saves/" & i & "-brake"):
      log_error "Package " & i & " is not braked."
      quit(1)
  removeFile("/etc/car/saves/" & i & "-brake")
  log_ok "Released " & i
