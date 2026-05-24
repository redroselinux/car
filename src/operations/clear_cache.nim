import os
import color
import strutils

proc clearCache*() =
  for i in walkDir("/var/cache", relative = true):
    if i.kind == pcFile and i.path.endsWith(".tar.zst"):
      let pkg = i.path.replace(".tar.zst", "")
      log_pick "Deleting cache for package " & pkg
      removeFile("/var/cache/" & i.path)
