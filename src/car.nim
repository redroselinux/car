import os
import color
import posix

import operations.init
import operations.listup
import operations.install

var initMode = false

proc isRoot() =
  if geteuid() != 0:
    log_error("this operation must be run as root")
    quit()

proc usage() =
  log_info("Usage: car [options]")
  log_info("Options: (F = flag)")
  log_info("  -v, --version   Show version information and exit")
  log_info("  init            Initialize Car")
  log_info("F --force         Force initialization when already initialized")
  log_info("  listup          Update list of packages")
  log_info("  install         Install packages")

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
      elif arg == "install":
        if args.len < 2:
          log_error("missing package name")
          usage()
          quit()
        isRoot()
        let installArgs = args[(i+1)..^1]
        install(installArgs)
        quit()
      elif arg in ["--force"]:
        continue
      else:
        log_error("unknown option: " & arg)
        usage()
        quit()
      inc(i)
