V ?= @

YACC = bison -y -d
LEX = flex
CC = gcc
TOP = ..
TARGET = $(TOP)/bin/rain

CDEFS = 
CFLAGS = -std=c99 -g -ggdb -Wall $(CDEFS)
LIBS = 

TESTS = $(wildcard $(TOP)/examples/*.lua)

SRCS = $(filter-out y.tab.c lex.yy.c, $(wildcard *.c))
OBJS := $(SRCS:.c=.o) parse.o
DEPS := $(OBJS:.o=.d)

all : $(TARGET)

.PHONY : all

test : all
	$(MAKE) -C $(TOP) $@

%.o : %.c
	$(CC) $(CFLAGS) -MMD -MP -c -o $@ $<

.PHONY : test

y.tab.c y.tab.h : parse.y lex.yy.c
	$(YACC) -o y.tab.c parse.y

lex.yy.c lex.yy.h : lex.l
	$(LEX) --header-file=lex.yy.h -o lex.yy.c lex.l

parse.o : y.tab.c lex.yy.c
	$(CC) -g -MMD -MP -c y.tab.c -o parse.o

node.o : y.tab.h lex.yy.h

$(TARGET) : $(OBJS)
	mkdir -p "$$(dirname $(TARGET))"
	$(CC) $(CFLAGS) $(OBJS) -o $(TARGET) $(LIBS)


clean:
	rm -f y.output y.tab.c y.tab.h
	rm -f lex.yy.c lex.yy.h
	rm -f *.d *.o $(TARGET)

.PHONY: clean

-include $(DEPS)
