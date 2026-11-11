#include <base.h>
#include <stdlib.h>

#include "include/handle.h"

RacHandle* rac_handle_init(const string car_conf_dir) {
  var result = (RacHandle*) malloc(sizeof(RacHandle));

  result->car_conf_dir = (string) car_conf_dir;

  return result;
}

RacHandle* rac_handle_init_default() {
  return rac_handle_init("/etc/car");
}

void rac_handle_free(RacHandle* rac) {
  free(rac);
}
