import os
import ../color
import listup
import install
import strutils

proc update*() =
  discard listup()
  log_info("reading lists")
  let packagelist = readFile("/etc/car/packagelist")
  let repro = readFile("/etc/repro.car")
  log_info("populating lists")
  var installed = newSeq[string]()
  var updatable = newSeq[string]()
  for line in repro.splitLines():
    if line.contains('='):
      installed.add(line.split('=')[0].strip())
  for line in packagelist.splitLines():
    if line.contains(" - "):
      let pkg = line.split(" - ")[0].strip()
      let version = line.split(" - ")[1].strip()
      if pkg in installed:
        for i in repro.splitLines():
          if i.contains(pkg):
            if i.contains(" - "):
              let version = i.split(" - ")[1].strip()
              if version != version:
                updatable.add(pkg)
  if updatable.len == 0:
    log_ok("system is up to date")
    return
  log_info("updating " & $updatable.len & " packages:")
  log_info(updatable.join(", "))
  for i in updatable:
    install(@[i])
