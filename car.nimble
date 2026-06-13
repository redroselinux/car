version = "3.15"
author = "Juraj Kollár"
description = "A new awesome nimble package"
license = "GPL-3.0-only"
srcDir = "src"
bin = @["car"]

switch("mm", "arc")

requires "nim >= 2.2.6"
