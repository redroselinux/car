import os
import ../color

proc rareBuild*(packages: seq[string]) =
  # check if dependencies are installed
  for i in ["docker", "git", "nim", "nimble"]:
    if findExe(i) == "":
      log_error "missing dependency " & i
      quit(1)

  for package in packages:
    # attempt to cleanup any old instance
    discard execShellCmd("rm -rf /tmp/rarebuild")

    # why do we redownload everything?
    # because this is meant to be a fully clean build.
    log_info("downloading rare")
    if execShellCmd("git clone https://github.com/redroselinux/rare /tmp/rarebuild") != 0:
      log_error("failed to download rare")
      quit(1)

    setCurrentDir("/tmp/rarebuild")

    # rare is the worst piece of software by redrose;
    # yes, this is how it actually works for real.
    log_info("compiling rare")
    if execShellCmd("nimble build") != 0:
      log_error("compiling rare failed")
      quit(1)

    log_info("starting build")
    if execShellCmd("./rare build " & package) != 0:
      log_error("failed to compile " & package)
      quit(1)
    copyFile("/tmp/rarebuild/" & package & ".tar.zst", "/tmp/" & package & ".tar.zst")
    log_ok("compiled " & package)
    setCurrentDir("/tmp")
  log_done("compiled all\n")
  log_info("results are located in: ")
  for i in packages:
    echo "      /tmp/" & i & ".tar.zst"
