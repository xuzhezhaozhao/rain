V ?= @
TARGET = bin/rain

TESTS = $(wildcard examples/*.lua)

.PHONY : all test clean

all clean:
	$(MAKE) -C src $@

test : all
	$(TARGET) -c $(TESTS)
