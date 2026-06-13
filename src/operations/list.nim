import color
import strutils

proc listInstalled*() =
  let repro_car = readFile("/etc/repro.car")
  for i in repro_car.splitLines():
    if i == "": continue

    let package = i.split("=")[0]
    let version = i.split("=")[1]
    log_info package & " " & version

proc listPackageFiles*(package: string) =
  var saveFile: string
  try:
    saveFile = readFile("/etc/car/saves/" & package)
  except:
    log_error "Package " & package & " not installed."
    quit 1

  for line in saveFile.splitLines():
    if not (line == "" or line == "car"):
      log_info line
