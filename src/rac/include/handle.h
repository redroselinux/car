#pragma once

// cant use fun.c here;
#define string char*

typedef struct {
  string car_conf_dir;
} RacHandle;

RacHandle* rac_handle_init_default();
RacHandle* rac_handle_init(const string car_conf_dir);

void rac_handle_free(RacHandle* rac);
