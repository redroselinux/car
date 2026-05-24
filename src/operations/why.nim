import os
import color
import strutils
import sequtils

proc whyInstalled*(packages: seq[string]) =
  for package in packages:
    let repro = readFile("/etc/repro.car")
    if not repro.splitLines().anyIt(it.startsWith(package & "=")):
      log_error "Package not installed: " & package
      quit(1)

    var strap = false
    var update = false
    var manual_install = false

    try:
      let redrose_strap = readFile("/etc/redrose-strap")
      if redrose_strap.splitLines().anyIt(it.strip() == package):
        strap = true
    except:
      discard

    if fileExists("/etc/car/saves/" & package & "-update"):
      update = true

    if not (strap or update):
      if fileExists("/etc/car/saves/" & package):
        manual_install = true
      else:
        log_error "Package seems to be installed, but car is not able to find its savefile."
        quit(1)

    if strap:
      log_info package & " came preinstalled with redrose"
    elif update:
      log_info "An update triggered installation of " & package
    elif manual_install:
      log_info "You installed " & package & " manually"
