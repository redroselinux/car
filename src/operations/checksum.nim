import os
import color
import strutils

# Great func name, innit?? Said me in a british accent.

proc checkSumOfFilesOfAPackage*(package: string) =
  let carSavePath = "/etc/car/saves/" & package
  var file: string
  try:
    file = readFile carSavePath
  except:
    log_error("Package is not installed: " & package)
    quit 1
  
  for i in file.splitLines():
    let path = "/" & i
    if i == "car": continue
    if dirExists(path): continue
    if execShellCmd("sha256sum " & path) != 0:
      log_error("Failed to calculate checksum for " & path)
      quit 1