proc log_error*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[91merror\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")

proc log_warn*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[93mwarning\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")

proc log_ok*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[92mok\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")

proc log_done*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[92mdone\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")

proc log_info*(msg: string) {.inline.} =
  stdout.write("\e[1m\e[94minfo\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")

proc log_pick*(msg: string) {.inline.} =
  stdout.write("\e[1;36mpick\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")

proc log_option*(msg: string) {.inline.} =
  stdout.write("\e[1;30moption\e[0m: ")
  stdout.write(msg)
  stdout.write("\n")
