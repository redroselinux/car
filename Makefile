CC = gcc
.PHONY: all clean
CFLAGS = -O3 -march=native

car: src/car/main.c .always_rebuild
	$(CC) $< -o $@ $(CFLAGS)

.always_rebuild:
clean:
	rm -f ./car

all: clean car

