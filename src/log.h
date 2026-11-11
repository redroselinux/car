#pragma once

#include <base.h>

#define __LOG_DEFINE(name, prefix) \
  static inline void log_##name(string message) { \
    print(prefix); \
    println(message); \
  }

__LOG_DEFINE(error, "\x1b[1m\x1b[91mx\x1b[0m ")
__LOG_DEFINE(warn, "\x1b[1m\x1b[93m⚠\x1b[0m ")
__LOG_DEFINE(ok, "\x1b[1m\x1b[92m✔\x1b[0m ")
__LOG_DEFINE(done, "\x1b[1m\x1b[32m✔\x1b[0m ")
__LOG_DEFINE(info, "\x1b[1m\x1b[94m→\x1b[0m ")
__LOG_DEFINE(pick, "\x1b[1;36m→\x1b[0m ")
__LOG_DEFINE(option, "\x1b[1;30m→\x1b[0m ")
