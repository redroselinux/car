import strutils
import color
import posix
import os

proc convertAppImage*(appimage: string): string =
  let file = absolutePath(appimage)

  # use /var/tmp because /tmp is ram and appimages are big
  var workingDir = file.lastPathPart().replace(".AppImage", "")
  # no collisions, i love /var/tmp/pkg___________
  while dirExists("/var/tmp/" & workingDir):
    workingDir &= "_"
  let absWorkDir = "/var/tmp/" & workingDir
  createDir(absWorkDir)
  setCurrentDir(absWorkDir)

  var version = "none"

  log_info "Extracting the AppImage"
  if chmod(file, 0o755) != 0:
    log_error "Failed to set execute permission bit on the AppImage."
    quit 1
  if execShellCmd(file & " --appimage-extract") != 0:
    log_error "Failed to extract the AppImage."
    quit 1

  log_info "Finding the package name"
  # AppImageNameFinder Pro Max | starting 700$
  var name = "unknown"
  var appimage_icon = "" # for the 2nd method
  for kind, path in walkDir("squashfs-root/"):
    if path.endsWith(".desktop"):
      # found it! extract the name
      for line in readFile(path).splitLines():
        if line.startsWith("Name="):
          # get the original name, not in lowercase
          let orig_name = line[5..^1] # if the app has = in the name
          if orig_name == "":         # it would break with replace()
            log_warn "Name is empty, trying another method to find package name."
            break
          # make the name lowercase
          name = orig_name.toLowerAscii()
        if line.startsWith("X-AppImage-Version="):
          version = line[19..^1]
    if path.endsWith(".png"):
      appimage_icon = path.replace(".png", "")
  # check if we dont have the name
  if name == "unknown":
    # try to guess using the icon we saved earlier
    name = appimage_icon.replace(".png", "")
    log_info "Found the name by reading the icon name."
  # IF WE STILL DONT HAVE THAT SHIT
  if name == "unknown":
    log_error "Car was not able to find the package name with any method."
    while name == "" or name == "unknown":
      stdout.write "  Please type the package name: "
      name = readLine(stdin)

  log_info "Creating the package"
  createDir("package")
  createDir("package/usr")
  createDir("package/usr/bin")
  copyFile(file, "package/usr/bin/" & name)
  if chmod("package/usr/bin/" & name, 0o755) != 0:
    log_error "Failed to set execute permission bit."
    quit 1
  writeFile(
    "package/car",
    "exec printf \"\e[1m\e[93m⚠\e[0m This package is converted from an AppImage\\n\"\nversion " & version
  )

  log_info "Compressing the package"
  if execShellCmd(
    "tar -I zstd -cf /var/tmp/" & name & ".tar.zst package"
  ) != 0:
    log_error "Failed to compress the package."
    quit 1

  log_info "Cleaning up..."
  setCurrentDir("/var/tmp")
  removeDir(absWorkDir)

  return "/var/tmp/" & name & ".tar.zst"
