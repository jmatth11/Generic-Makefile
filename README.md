# The 90% Makefile

Contents:
- Introduction
- Project Setup
- Makefile
- Conclusion

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
│   ├── lib.(so|a)
│   └── exe
├── obj
│   └── <object files>
├── deps
│   └── <third party deps>
└── src
    ├── lib
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
- `src/lib` The common code (like for a library).

## Makefile

Now that you know what folder structure to expect we can look at the Makefile.
First we'll look at the Makefile and then we will break it down.

```Makefile
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
```

### The Common Variables

At the top we have our common variables to define our compiler, compiler flags,
library paths, and includes paths.

Add or remove anything from these variables to fit your project's requirements.

```Makefile
# define our compiler
CC=gcc
# define our generic compiler flags
CFLAGS=-Wall -Wextra -std=c11
# define the paths to our third party libraries
LIBS=-L./deps/example_lib/build -lexample_lib.so -lm
# define the paths to our include directories
INCLUDES=-I./src -I./deps/example_lib/include
```

### The Source Files

We expect all of our source files to be under the `src` folder. So we use
`find` to grab all of them. By default we assume we are compiling for an executable,
we can change this later with some conditional logic.

```Makefile
# define variables for our source files
# we use find to grab them
SOURCES=$(shell find ./src -name '*.c')
```

### The Dependencies

We want to automate compiling our third party dependencies as well so we grab their
Makefiles at the top of their directories. We exclude any unittest directories.

This might need to change as well depending on what third party dependencies you use.

```Makefile
# define variable for our dependencies' Makefiles.
# we use find to grab only the top level Makefiles and also some convenient ignores.
DEPS=$(shell find ./deps -maxdepth 2 -name Makefile -printf '%h\n' | grep -v 'unittest')
```

### Folders & Target

We always need a `bin` and `obj` folder. We default the target to an executable
name (this can change with conditional logic).

```Makefile
# define folder paths and names
OBJ=obj
BIN=bin
TARGET=main
```

### Conditional Flags

We setup some conditional flags we can pass to `make`. We define `DEBUG`,
`RELEASE`, and `SHARED` already. The `DEBUG` and `RELEASE` modify the `CFLAGS`
to better align with their respective states.

The `SHARED` flag is independant from the other conditional flags because it changes
what source files we use and the `TARGET` name.

```Makefile
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
```

### Object Files

We setup our Object files next so we can construct them based on what the `SOURCES`
variable is conditionally set to.

```Makefile
# This variable is for our object files.
# We take the files in SOURCES and rename them to end in .o
# Then we add our OBJ folder prefix to all files.
OBJECTS=$(addprefix $(OBJ)/,$(SOURCES:%.c=%.o))
```

### The Jobs

The rest of the Makefile are the jobs.

#### Default Job

The first one is the default job. It's an empty job but we use it to set
up the dependency tree for our Makefile.

We first depend on `deps` then `src`.

```Makefile
# We setup our default job
# it will build dependencies first then our source files.
.PHONY: all
all: deps src
```

#### Source Job

We setup our `src` job to have a dependency on the Object files we defined.

Inside the job we create the `bin` directory if it doesn't exist then we conditionally
execute code to build either libraries or an executable.

All the places you see `$^` is Makefile magic to reference everything in the dependency
list (which are all the files in `OBJECTS`).

```Makefile
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
```

#### Object Files Job

The object files job looks a little weird at first but the job name is a wildcard.
It matches anything with the signature `$(OBJ)/%.o` which is what all of our files
listed in the `OBJECTS` variable match.

The `%.c` dependency is some Makefile magic to find the source file with the same path
except the `$(OBJ)/` part.

There are 2 other Makefile magic symbols that need some explaining in here.
First is the `$@` symbol to reference the left side of the job signature
(the `$(OBJ)/%.o` side).
Second is the `$<` symbol to reference the first item in the dependency side of the
job signature (the `%.c` side).

```Makefile
# Compile all source files to object files
# This job executes because the `src` job depends on all the files in OBJECTS
# which has the `$(OBJ)/%.o` file signature.
$(OBJ)/%.o: %.c
	@mkdir -p $(dir $@)
	$(CC) -c -o $@ $< $(CFLAGS) $(INCLUDES)
```

#### Clean Jobs

The next section are all the jobs related to clean up.

The first job is to clean our project. You'll notice we pipe the errors to
`/dev/null` this is because we get errors if the folders are empty when cleaning.

The second job is to run `make clean` on all of the dependencies. We need to call
make as `$(MAKE)` for it to execute properly.

The last job is to do both of the cleanup jobs together.

```Makefile
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
```

#### Dependency Job

The last job in the Makefile is to compile our third party dependencies.
This command iterates over the Makefiles we captured in the `DEPS` variable
and runs `make`. This assumes the third party dependencies have a default job setup
and it's the one you want to run.

This section may need to change depending on your projects needs.

```Makefile
# Job to run `make` on all of our dependencies.
# This only works if the dependencies' Makefile is at the top and implements a
# default job.
.PHONY: deps
deps:
	$(foreach dir, $(DEPS), $(shell cd $(dir) && $(MAKE)))
```

## Conclusion

Hopefully this Makefile helps you, if not fully, maybe it at least gets you started
in having something that can cover the uses you need.
