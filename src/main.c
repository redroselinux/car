#include <base.h>
#include <stddef.h>
#include <string.h>
#include "log.h"

int entry(heap_array args) {
  if (args->length == 1) {
    log_error("Not enough args");
    log_info("Use --help to show usage information");
    return 2;
  }

  var arg_used = false;

  for (size_t i = 1; i < args->length; i++) {
    let arg = ((string *)args->data)[i];

    if (!strcmp(arg, "--version")) {
      log_info("Car " CAR_VERSION " (GPLv3)\n");
      log_info("Authors");
      log_info("mostypc123 <mostypc123@redroselinux.org>");

      return 0;
    }

    if (!strcmp(arg, "--help")) {
      log_info("\e[1m--version\e[0m");

      return 0;
    }
  }

  if (!arg_used) {
    log_error("Incorrect arguments");
    log_info("Use --help to show usage information");
    return 2;
  }

  return 0;
}
