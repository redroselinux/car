import std/strutils

version = "3.16"
author = "Juraj Kollár"
description = "Package manager for Redrose Linux"
license = "GPL-3.0-only"
srcDir = "src"
bin = @["car"]

switch("mm", "arc")

requires "nim >= 2.2.6"

task syncVersion, "Sync version from Version file into car.nimble":
  let v = readFile("Version").strip()
  var lines = readFile("car.nimble").splitLines
  for i, line in lines:
    if line.startsWith("version "):
      lines[i] = "version = \"" & v & "\""
  writeFile("car.nimble", lines.join("\n"))
