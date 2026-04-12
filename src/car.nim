import os
import color
import posix
import strutils

import operations/init
import operations/listup
import operations/install
import operations/delete
import operations/update
import operations/rarebuild

{.passC: "-O3 -flto -funroll-loops -fstrict-aliasing -fomit-frame-pointer -ftree-vectorize -fprefetch-loop-arrays -floop-interchange -floop-block -floop-unroll-and-jam -ffast-math -fassociative-math -fno-trapping-math".}

var initMode = false
var searchMode = false

proc isRoot() =
  if geteuid() != 0:
    log_error "this operation must be run as root"
    quit()

proc usage() =
  log_info "Usage: car [command] [options] [flags]"
  log_info "You can mix commands: sudo car listup install example"
  log_info "Options:"
  log_info "  -v, --version   show version information and exit"
  log_info "  init |Flags|    initialize car"
  log_info "       --force    force initialization when already initialized"
  log_info "  listup          update list of packages"
  log_info "  install         install packages"
  log_info "  delete          delete packages"
  log_info "  update          run listup and perform a system upgrade"
  log_info "  search          search for packages"
  log_info "  cleanbuild      use rare to compile a package in docker"
  log_info ""
  log_info "License: GPLv3-only"
  log_info "Authors: Juraj Kollár <mostypc7@gmail.com>"

when isMainModule:
  var args = commandLineParams()
  if args.len == 0:
    usage()
    quit()
  else:
    var i = 0
    while i < args.len:
      let arg = args[i]
      if searchMode:
        if isInited():
          discard execShellCmd("cat /etc/car/packagelist | grep '" & arg.replace("$(", "") & " - '")
          quit()
        else:
          log_error "car is not inited. did you run 'car init'?"

      if arg == "-v" or arg == "--version" or arg == "version":
        log_info(
          "car version 3.10 (nim rewrite of c rewrite of origin python version) (" &
          CompileDate & ", " & CompileTime & ") [Nim " &
          NimVersion & "] on " & hostOS
        )
        log_info "author: mostypc123 <mostypc7@gmail.com>"
        log_info "source: https://github.com/redroselinux/car"
        quit()
      elif arg == "init":
        isRoot()
        if "--force" in args:
          init true
        else:
          init false
      elif arg == "update":
        isRoot()
        update()
      elif arg == "listup":
        isRoot()
        listup()
        quit()
      elif arg in ["install", "get", "i"]:
        if args.len < 2:
          log_error "missing package name"
          usage()
          quit()
        isRoot()
        let installArgs = args[(i+1)..^1]
        install installArgs
        quit()
      elif arg == "cleanbuild":
        if args.len < 2:
          log_error "missing package name"
          usage()
          quit()
        isRoot()
        let installArgs = args[(i+1)..^1]
        rareBuild installArgs
        quit()
      elif arg == "delete":
        if args.len < 2:
          log_error "missing package name"
          usage()
          quit()
        isRoot()
        let deleteArgs = args[(i+1)..^1]
        delete deleteArgs
        quit()
      elif arg in ["--force"]:
        continue
      elif arg == "search":
        searchMode = true
      else:
        log_error "unknown option: " & arg
        usage()
        quit()
      inc(i)
