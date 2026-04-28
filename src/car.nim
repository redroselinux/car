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
  echo "\e[1m\e[93mcar\e[0m v3.14"
  echo ""

  echo "\e[1mUsage:\e[0m"
  echo "  car [command] [options] [flags]"
  echo "\e[3m  You can mix commands (e.g. sudo car listup install example)\e[0m"
  echo ""

  echo "\e[1mOptions:\e[0m"
  echo "  -v, --version        Show version information and exit"
  echo ""

  echo "\e[1mCommands:\e[0m"

  echo "  \e[36minit\e[0m                 Initialize car"
  echo "    --force            Force initialization if already initialized"
  echo "\e[3m  car init\e[0m"
  echo "\e[3m  car init --force\e[0m"
  echo ""

  echo "  \e[36mlistup\e[0m               Update list of packages"
  echo "\e[3m  car listup\e[0m"
  echo ""

  echo "  \e[36minstall\e[0m              Install packages"
  echo "\e[3m  car install example\e[0m"
  echo "\e[3m  car install legacy::example\e[0m"
  echo ""

  echo "  \e[36mdelete\e[0m               Delete packages"
  echo "\e[3m  car delete example\e[0m"
  echo ""

  echo "  \e[36mupdate\e[0m               Run listup and perform system upgrade"
  echo "\e[3m  car update\e[0m"
  echo ""

  echo "  \e[36msearch\e[0m               Search for packages"
  echo "\e[3m  car search h\e[0m"
  echo ""

  echo "  \e[36mcleanbuild\e[0m           Compile a package in Docker using rare"
  echo "\e[3m  car cleanbuild nm\e[0m"
  echo ""

  echo "\e[3mLicense: GPLv3-only\e[0m"
  echo "\e[3mAuthors: Juraj Kollár <mostypc123@redroselinux.org>\e[0m"

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
          log_error "Car is not initialized. Did you run 'car init'?"

      if arg in ["-v", "--version"]:
        echo "\e[1m\e[93mcar\e[0m version \e[1m3.14\e[0m"
        echo "\e[3;2mnim rewrite of c rewrite of original python version\e[0m"
        echo ""
        echo "\e[1mbuilt\e[0m: " & CompileDate & " " & CompileTime
        echo "\e[1mnim\e[0m:   " & NimVersion
        echo "\e[1mos\e[0m:    " & hostOS
        echo ""
        echo "\e[1mAuthor\e[0m: mostypc123 <mostypc123@redroselinux.org>\e[0m"
        echo "\e[1mSource\e[0m: https://github.com/redroselinux/car\e[0m"
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
          log_error "Missing package name"
          quit()
        isRoot()
        let installArgs = args[(i+1)..^1]
        install installArgs
        quit()
      elif arg == "cleanbuild":
        if args.len < 2:
          log_error "Missing package name"
          quit()
        isRoot()
        let installArgs = args[(i+1)..^1]
        rareBuild installArgs
        quit()
      elif arg == "delete":
        if args.len < 2:
          log_error "Missing package name"
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
        log_error "Unknown option: " & arg
        quit()
      inc(i)
