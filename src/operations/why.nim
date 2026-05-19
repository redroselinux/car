import ../color
import os
import strutils

proc whyInstalled*(packages: seq[string]) =
  for package in packages:
    if not (package in readFile("/etc/repro.car")):
      log_error "Package not installed."
      quit(1)

    var strap = false
    var manual_install = false
    var update = false

    # if the package + a newline or a newline + the package is in
    # /etc/redrose-strap, the package was copied during install
    try:
      let redrose_strap = readFile("/etc/redrose-strap")
      if (package & "\n" in redrose_strap) or ("\n" & package in redrose_strap):
        strap = true
    except:
      # testing on a non-redrose system; skip
      discard

    # if /etc/car/saves/pkg-up exists, the package was installed by
    # a maintainer-issued update; like adding a new redrose cli tool
    try:
      discard readFile("/etc/car/saves/" & package & "-up")
      update = true
    except:
      update = false

    # if none of these above are true, and /etc/car/saves/package exists,
    # the package was installed manually.
    if not (strap or update):
      try:
        discard readFile("/etc/car/saves/" & package)
        manual_install = true
      except:
        log_error "Package seems to be installed, but car is not able to find its savefile."
        quit(1)

    # print result
    if strap:
      log_info package & " came preinstalled with redrose"
    elif update:
      log_info "An update triggered installation of " & package
    elif manual_install:
      log_info "You installed " & package & " manually"
