#include <stdio.h>
#include <string.h>
#include <unistd.h>

#include "../rac/install.c"
// #include "../tui.c"
// included in frontend so we need to keep it commented

// package builders are included in the frontend, not the backend.

int check_root() {
  if (getuid() != 0) {
    log_error("not running as root.");
    return 2;
  }
  return 0;
}

int main(int argc, char **argv) {
  if (argc < 2) {
      log_error("too little arguments");
      return 2;
  }

  if (strcmp(argv[1], "get") == 0) {
    if (check_root() != 0)
      return 1;
    if (argc < 3) {
      log_error("0 packages specified");
      return 2;
    }

    for (int i = 2; i < argc; i++) {
      install(argv[i]);
    }
    char msg[100];
    if (argc == 3) {
      snprintf(msg, sizeof(msg), "installed %d package", argc - 2);
      log_done(msg);
    } else {
      snprintf(msg, sizeof(msg), "installed %d packages", argc - 2);
      log_done(msg);
    }
  } else {
    log_error("no instruction specified");
    return 2;
  }

  return 0;
}

