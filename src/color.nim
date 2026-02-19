proc log_error*(message: string) =
  echo "\e[1m\e[91merror\e[0m: " & message

proc log_warn*(message: string) =
  echo "\e[1m\e[93mwarning\e[0m: " & message

proc log_ok*(message: string) =
  echo "\e[1m\e[92mok\e[0m: " & message

proc log_done*(message: string) =
  echo "\e[1m\e[92mdone\e[0m: " & message

proc log_info*(message: string) =
  echo "\e[1m\e[94minfo\e[0m: " & message
