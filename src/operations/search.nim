import color
import strutils

proc searchForPackage*(package: string) =
  let packagelist = readFile "/etc/car/packagelist"
  var nextLineIsVersion = false
  var currentPkg: string

  for i in packagelist.splitLines():
    let pkg = i.split(" - ")[0]
    if package in pkg:
      currentPkg = pkg
      nextLineIsVersion = true
      continue

    if nextLineIsVersion:
      if currentPkg == package:
        log_pick("\e[97m" & currentPkg & " version " & i.split(" ")[1] & "\e[0m")
      else:
        log_option(currentPkg & " version " & i.split(" ")[1])
      nextLineIsVersion = false
