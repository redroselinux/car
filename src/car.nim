import os
import color
import posix
import strutils

import operations/init
import operations/repo
import operations/install
import operations/delete
import operations/update
import operations/why
import operations/clear_cache
import operations/search
import operations/brake
import operations/list

{.passC: "-O3 -flto -funroll-loops -fstrict-aliasing -fomit-frame-pointer " &
         "-ftree-vectorize -fprefetch-loop-arrays -floop-interchange " &
         "-floop-block -floop-unroll-and-jam -ffast-math -fassociative-math " &
         "-fno-trapping-math".}

var initMode = false
var searchMode = false
var tiresMode = false

# the Version file
const VERSION = staticRead("../Version")

proc isRoot() =
  if geteuid() != 0:
    log_error "This operation must be run as root"
    quit()

proc usage() =
  log_info "\e[1m\e[93mcar\e[0m v" & VERSION
  log_info "\e[1mUsage:\e[0m"
  echo "  car [command] [options] [flags]"
  echo "\e[3m  You can mix some commands (e.g. sudo car listup install example)\e[0m"
  echo ""
  log_info "\e[1mOptions:\e[0m"
  echo "  -v, --version        Show version information and exit"
  echo ""
  log_info "\e[1mCommands:\e[0m"
  echo "  \e[36minit\e[0m                 Initialize car"
  echo "    --force            Force initialization if already initialized"
  echo "\e[3m  car init\e[0m"
  echo "\e[3m  car init --force\e[0m"
  echo "  \e[36mlistup\e[0m               Update list of packages"
  echo "\e[3m  car listup\e[0m"
  echo "  \e[36minstall\e[0m              Install packages, supports Car .tar.zst, Pacman .pkg.tar.zst, AppImage and DPKG .deb"
  echo "\e[3m  car install example\e[0m"
  echo "\e[3m  car install legacy::example\e[0m"
  echo "  \e[36mdelete\e[0m               Delete packages"
  echo "\e[3m  car delete example\e[0m"
  echo "  \e[36mupdate\e[0m               Run listup and perform system upgrade"
  echo "\e[3m  car update\e[0m"
  echo "  \e[36msearch\e[0m               Search for packages"
  echo "\e[3m  car search h\e[0m"
  echo "  \e[36mwhy\e[0m                  Why is this package installed?"
  echo "\e[3m  car why h\e[0m"
  echo "  \e[36mlist\e[0m                 List all installed packages"
  echo "  \e[36mclearcache\e[0m           Clear all cache"
  echo "  \e[36mbrake/release\e[0m        Do not/do update this package"
  echo "\e[3m  car brake bun-js     \e[2myk why\e[0m"
  echo "  \e[36maddrepo\e[0m               Add a repository/mirror"
  echo "\e[3m  car addrepo https://example.com/repo\e[0m\n"
  log_info "\e[3mLicense: GPLv3-only\e[0m"
  log_info "\e[3mAuthor: Juraj Kollár <mostypc123@redroselinux.org>\e[0m"

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
          searchForPackage(arg)
          quit()
        else:
          log_error "Car is not initialized. Did you run 'car init'?"
      elif tiresMode:
        listPackageFiles(arg)
        quit 0

      if arg in ["-v", "--version"]:
        echo "\e[1m\e[93mcar\e[0m version \e[1m" & VERSION & "\e[0m"
        echo "\e[3;2mnim rewrite of c rewrite of original python version\e[0m"
        echo ""
        echo "\e[1mbuilt\e[0m: " & CompileDate & " " & CompileTime
        echo "\e[1mnim\e[0m:   " & NimVersion
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
        log_error "This option is removed in Car 3.16."
        log_info "Use the program 'fuel' as a replacement."
        quit 2
      elif arg == "clearcache":
        isRoot()
        clearCache()
      elif arg == "delete":
        if args.len < 2:
          log_error "Missing package name"
          usage()
          quit()
        isRoot()
        let deleteArgs = args[(i+1)..^1]
        delete deleteArgs
        quit()
      elif arg == "why":
        if args.len < 2:
          log_error "Missing package name"
          usage()
          quit()
        whyInstalled args[(i+1)..^1]
        quit(0)
      elif arg == "brake":
        if args.len < 2:
          log_error "Missing package name"
          usage()
          quit()
        brakePackages args[(i+1)..^1]
        quit(0)
      elif arg == "release":
        if args.len < 2:
          log_error "Missing package name"
          usage()
          quit()
        releasePackages args[(i+1)..^1]
        quit(0)
      elif arg in ["addrepo", "add-repo"]:
        if args.len < 2:
          log_error "Missing repository URL"
          usage()
          quit()
        isRoot()
        addRepo args[i+1]
        quit(0)
      elif arg in ["--force"]:
        continue
      elif arg == "list":
        listInstalled()
      elif arg == "search":
        searchMode = true
      elif arg == "tires":
        tiresMode = true
      else:
        log_error "Unknown option: " & arg
        quit()
      inc i
