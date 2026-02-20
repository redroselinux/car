import os
import color
import posix

import operations/init
import operations/listup
import operations/install
import operations/delete

var initMode = false

proc isRoot() =
  if geteuid() != 0:
    log_error("this operation must be run as root")
    quit()

proc usage() =
  log_info("Usage: car [options]")
  log_info("Options: (F = flag)")
  log_info("  -v, --version   show version information and exit")
  log_info("  init            initialize car")
  log_info("F --force         force initialization when already initialized")
  log_info("  listup          update list of packages")
  log_info("  install         install packages")
  log_info("  delete          delete packages")
  log_info("")
  log_info("License: GPLv3-only")
  log_info("Authors: Juraj Kollár <mostypc7@gmail.com>")

when isMainModule:
  var args = commandLineParams()
  if args.len == 0:
    usage()
    quit()
  else:
    var i = 0
    while i < args.len:
      let arg = args[i]
      if arg == "-v" or arg == "--version" or arg == "version":
        log_info("car version 3.0 (nim rewrite)")
        quit()
      elif arg == "init":
        isRoot()
        if "--force" in args:
          init(true)
        else:
          init(false)
      elif arg == "listup":
        isRoot()
        listup()
      elif arg in ["install", "get", "i"]:
        if args.len < 2:
          log_error("missing package name")
          usage()
          quit()
        isRoot()
        let installArgs = args[(i+1)..^1]
        install(installArgs)
        quit()
      elif arg == "delete":
        if args.len < 2:
          log_error("missing package name")
          usage()
          quit()
        isRoot()
        let deleteArgs = args[(i+1)..^1]
        delete(deleteArgs)
        quit()
      elif arg in ["--force"]:
        continue
      else:
        log_error("unknown option: " & arg)
        usage()
        quit()
      inc(i)
