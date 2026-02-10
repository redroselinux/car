#include <ctype.h>

char *trim(char *s){
  while (isspace((unsigned char)*s)) s++;
  char *e = s;
  while (*e) e++;
  while (e > s && isspace((unsigned char)e[-1])) e--;
  *e = 0;
  return s;
}

