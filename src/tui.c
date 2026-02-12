#include <stdio.h>

void log_error(char *message) {
  printf("\033[1m\033[91merror\033[0m: %s\n", message);
}

void log_warning(char *message) {
  printf("\033[1m\033[93mwarning\033[0m: %s\n", message);
}

void log_ok(char *message) {
  printf("\033[1m\033[92mok\033[0m: %s\n", message);
}
void llog_ok(char *message) {
  printf("\n\033[1m\033[92mok\033[0m: %s\n", message);
}

void log_done(char *message) {
  printf("\033[1m\033[92mdone\033[0m: %s\n", message);
}

void log_info(char *message) {
  printf("\033[1m\033[94minfo\033[0m: %s", message);
}

