proc log_error*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[91mx\e[0m ")
  stdout.write(msg)
  stdout.write("\n")

proc log_warn*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[93m⚠\e[0m ")
  stdout.write(msg)
  stdout.write("\n")

proc log_ok*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[92m✔\e[0m ")
  stdout.write(msg)
  stdout.write("\n")

proc log_done*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[32m✔\e[0m ")
  stdout.write(msg)
  stdout.write("\n")

proc log_info*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[94m→\e[0m ")
  stdout.write(msg)
  stdout.write("\n")

proc log_pick*(msg: string) {.inline.} =
  stdout.write("\e[1;36m→\e[0m ")
  stdout.write(msg)
  stdout.write("\n")

proc log_option*(msg: string) {.inline.} =
  stdout.write("\e[1;30m→\e[0m ")
  stdout.write(msg)
  stdout.write("\n")
