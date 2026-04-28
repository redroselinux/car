import os
import ../color

proc rareBuild*(packages: seq[string]) =
  # check if dependencies are installed
  var missing = false
  for i in ["docker", "git", "nim", "nimble"]:
    if findExe(i) == "":
      log_error "Missing dependency: " & i
      missing = true
  if missing:
    quit(1)

  for package in packages:
    # attempt to cleanup any old instance
    discard execShellCmd("rm -rf /tmp/rarebuild")

    # why do we redownload everything?
    # because this is meant to be a fully clean build.
    log_info("Downloading rare")
    if execShellCmd("git clone https://github.com/redroselinux/rare /tmp/rarebuild") != 0:
      log_error("Failed to download rare")
      quit(1)

    setCurrentDir("/tmp/rarebuild")

    # rare is the worst piece of software by redrose;
    # yes, this is how it actually works for real.
    log_info("Compiling rare")
    if execShellCmd("nimble build") != 0:
      log_error("Compiling rare failed")
      quit(1)

    log_info("Starting build")
    if execShellCmd("./rare build " & package) != 0:
      log_error("Failed to compile " & package)
      quit(1)
    copyFile("/tmp/rarebuild/" & package & ".tar.zst", "/tmp/" & package & ".tar.zst")
    log_ok("Compiled " & package)
    setCurrentDir("/tmp")
  log_info("Results are located in: ")
  for i in packages:
    echo "      /tmp/" & i & ".tar.zst"
