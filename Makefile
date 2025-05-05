# define our compiler
CC=gcc
# define our generic compiler flags
CFLAGS=-Wall -Wextra -std=c11
# define the paths to our third party libraries
LIBS=-L./deps/example_lib/build -lexample_lib.so -lm
# define the paths to our include directories
INCLUDES=-I./src -I./deps/example_lib/include

# define variables for our source files
# we use find to grab them
SOURCES=$(shell find ./src -name '*.c')

# define variable for our dependencies' Makefiles.
# we use find to grab only the top level Makefiles and also some convenient ignores.
DEPS=$(shell find ./deps -maxdepth 2 -name Makefile -printf '%h\n' | grep -v 'unittest' | grep -v '^.$$')

# define folder paths and names
OBJ=obj
BIN=bin
TARGET=main

# setup up conditional build flags
# if debug is set to 1, add debug specific flags
ifeq ($(DEBUG), 1)
	CFLAGS += -DDEBUG=1 -ggdb
endif
# Release specific flags
ifeq ($(RELEASE), 1)
	CFLAGS += -O2
endif
# if SHARED flag is set, we prepare variables for building a shared/static library.
# we change the SOURCES variable to point to only the common source files.
# we also rename the TARGET to our library name.
ifeq ($(SHARED), 1)
    SOURCES=$(shell find ./src/lib -name '*.c')
    TARGET=my_lib
endif

# This variable is for our object files.
# We take the files in SOURCES and rename them to end in .o
# Then we add our OBJ folder prefix to all files.
OBJECTS=$(addprefix $(OBJ)/,$(SOURCES:%.c=%.o))

# We setup our default job
# it will build dependencies first then our source files.
.PHONY: all
all: deps src

# Build the source files.
# Conditional change to building for an executable or libraries.
# We also create the output BIN directory if it doesn't exist.
# This job depends on the OBJECT files.
.PHONY: src
src: $(OBJECTS)
	@mkdir -p $(BIN)
ifeq ($(SHARED), 1)
	$(CC) -shared -fPIC -o $(BIN)/$(TARGET).so $^ $(LIBS)
	ar -rcs $(BIN)/$(TARGET).a $^
else
	$(CC) $(CFLAGS) $(LIBS) $^ -o $(BIN)/$(TARGET)
endif

# Compile all source files to object files
# This job executes because the `src` job depends on all the files in OBJECTS
# which has the `$(OBJ)/%.o` file signature.
$(OBJ)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)

# Job to clean out all object files and exe/libs.
.PHONY: clean
clean:
	@rm -rf $(OBJ)/* 2> /dev/null
	@rm -f $(BIN)/* 2> /dev/null

# Job to run `make clean` on all dependencies.
.PHONY: clean_deps
clean_deps:
	$(foreach dir, $(DEPS), $(shell cd $(dir) && $(MAKE) clean))

# Job to clean dependencies and our files.
.PHONY: clean_all
clean_all: clean clean_deps

# Job to run `make` on all of our dependencies.
# This only works if the dependencies' Makefile is at the top and implements a
# default job.
.PHONY: deps
deps:
	$(foreach dir, $(DEPS), $(shell cd $(dir) && $(MAKE)))
