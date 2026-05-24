import os
import color
import strutils
import fsck_symlink_attacks

proc clearCache*() =
  for i in walkDir("/var/cache", relative = true):
    if i.kind == pcFile and i.path.endsWith(".tar.zst"):
      let pkg = i.path.replace(".tar.zst", "")
      log_pick "Deleting cache for package " & pkg
      fsckSymlinkAttacks("/var/cache/" & i.path)
      removeFile("/var/cache/" & i.path)
