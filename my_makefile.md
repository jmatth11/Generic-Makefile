# The 90% Makefile

- Introduction
- Project Setup
- Makefile


## Introduction

I've been doing a lot of side projects in the C language lately.
Which has lead me to write Makefiles for all the scenarios I encounter with each new project.

The more I modified the Makefiles I was using to satisfy each new project structure
has lead to a Makefile I barely need to change now.

!!
I know this Makefile won't solve all usecases but it tends to cover most of my needs.
!!

## Project Setup

To start, I'll show what a typical project setup looks like for me.

```bash
├── LICENSE
├── Makefile
├── README.md
├── compile_flags.txt
├── install_deps.sh
├── run.sh
├── resources
│   └── <resource files>
├── bin
│   ├── lib
│   └── exe
├── obj
│   └── <object files>
├── deps
│   └── lib
└── src
    ├── subfolder
    └── main.c
```

I'll quickly give a highlight of everything, but the folders are the important part.

- `LICENSE` the license.
- `Makefile` The Makefile.
- `README.md` The readme.
- `compile_flags.txt` Clangd file for LSP configuration.
- `install_deps.sh` Shell file to install dependencies.
- `run.sh` Shell script to run the generated executable.
- `resources` The resources folder.
- `bin` The folder for the target executable or library.
- `obj` The object files when compiling.
- `deps` The third party dependencies.
- `src` The source code.

## Makefile

Now that you know what folders structure to expect we can look at the Makefile.
First I'll show the Makefile and then break it down.

```Makefile
CC=gcc
CFLAGS=-Wall -Wextra -std=c11
LIBS=-L./deps/example_lib/build -lexample_lib.so
OBJ=obj
BIN=bin
INCLUDES=-I. -I./deps/example_lib/include
SOURCES=$(shell find . -name '*.c' -not -path './deps/*')
DEPS=$(shell find . -maxdepth 3 -name Makefile -printf '%h\n' | grep -v 'unittest' | grep -v '^.$$')
RESOURCE_DIR=./resources
TARGET=main

ifeq ($(DEBUG), 1)
	CFLAGS += -DDEBUG=1 -ggdb
endif
ifeq ($(RELEASE), 1)
	CFLAGS += -O2
endif
ifeq ($(LIB), 1)
    SOURCES=$(shell find ./src/lib -name '*.c')
    TARGET=my_lib
endif

OBJECTS=$(addprefix $(OBJ)/,$(SOURCES:%.c=%.o))

.PHONY: all
all: deps src

.PHONY: src
src: $(OBJECTS)
	@mkdir -p $(BIN)
ifeq ($(SHARED), 1)
	$(CC) -shared -fPIC -o $(BIN)/$(TARGET).so $^ $(LIBS)
	ar -rcs $(BIN)/$(TARGET).a $^
else
	$(CC) $(CFLAGS) $(LIBS) $^ -o $(BIN)/$(TARGET)
endif

$(OBJ)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)

.PHONY: clean
clean:
	@rm -rf $(OBJ)/* 2> /dev/null
	@rm -f $(BIN)/* 2> /dev/null

.PHONY: clean_deps
clean_deps:
	$(foreach dir, $(DEPS), $(shell cd $(dir) && $(MAKE) clean))

.PHONY: clean_all
clean_all: clean clean_deps

.PHONY: deps
deps:
	@for i in $(DEPS); do\
		cd $${i} && $(MAKE) && cd -;\
	done

```
