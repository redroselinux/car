import os
import color

proc fsckSymlinkAttacks*(path: string) =
  if symlinkExists(path):
    log_error("Refusing to operate on symlink: " & path)
    echo "  This prevented a Symlink Attack."
    quit(126)
