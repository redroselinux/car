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

int updatelist() {
    return system("curl -s -L -o /etc/car/packagelist https://github.com/redroselinux/car3-pkgs/raw/refs/heads/main/README");
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
      log_error("no packages specified");
      return 2;
    }

    for (int i = 2; i < argc; i++) {
      if (!strstr(argv[i], ".tar.zst")) {
        // read what do we need to download from /etc/car/packagelist
        FILE *pkglist = fopen("/etc/car/packagelist", "r");
        if (!pkglist) {
            log_warning("having to update packagelist");
            if (updatelist() != 0) {
                log_error("unable to update packagelist. exiting now");
                return 1;
            }
            pkglist = fopen("/etc/car/packagelist", "r");
            if (!pkglist) {
                log_error("failed to open packagelist after update");
                return 1;
            }
        }
        fseek(pkglist, 0, SEEK_END);
        long fsize = ftell(pkglist);
        fseek(pkglist, 0, SEEK_SET);
        char *buffer = malloc(fsize + 1);
        if (!buffer) {
            log_error("failed to allocate memory");
            fclose(pkglist);
            return 1;
        }
        fread(buffer, 1, fsize, pkglist);
        buffer[fsize] = '\0';
        fclose(pkglist);
        int linecount;
        char **lines = split_string_by_lines(buffer, &linecount);

        char *next_line = NULL;
        for (int j = 0; j < linecount; j++) {
            if (strcmp(lines[j], argv[i]) == 0) {
                if (j + 1 < linecount) {
                    // skip leading "- "
                    char *line = lines[j + 1];
                    while (*line == ' ' || *line == '-') line++;
                    next_line = strdup(line);
                }
                break;
            }
        }

        if (next_line) {
            log_info("downloading package and installing");
            fflush(stdout);

            char command[256];
            snprintf(command, sizeof(command),
              "curl -s -L -o /tmp/car.tar.zst \"%s\"",
              next_line
            );
            system(command);

            fputs("\r\033[K", stdout);
            fflush(stdout);

            free(next_line);
        } else {
            log_error("package not found");
            return 1;
        }

        for (int i = 0; i < linecount; i++) free(lines[i]);
        free(lines);
        free(buffer);
        install("/tmp/car.tar.zst", argv[i]);
      } else {
        install(argv[i], NULL);
      }
    }
  } else if (strcmp(argv[1], "updatelist") == 0) {
    updatelist();
    log_done("updated packagelist");
  } else {
    log_error("no instruction specified");
    return 2;
  }

  return 0;
}

