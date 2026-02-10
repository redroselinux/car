CC = gcc
.PHONY: all clean

car: src/car/main.c .always_rebuild
	$(CC) $< -o $@

.always_rebuild:
clean:
	rm -f ./car

all: clean car

