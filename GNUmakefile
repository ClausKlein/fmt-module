# Standard stuff

.SUFFIXES:
$(VERBOSE).SILENT:

MAKEFLAGS+= --no-builtin-rules
MAKEFLAGS+= --warn-undefined-variables

export hostSystemName=$(shell uname)

ifeq (${hostSystemName},Darwin)
  export LLVM_PREFIX:=$(shell brew --prefix llvm@19)
  export LLVM_ROOT:=$(shell realpath ${LLVM_PREFIX})

  export LDFLAGS?=-L${LLVM_ROOT}/lib/c++
  export PATH:=${LLVM_ROOT}/bin:${PATH}
  export CXX:=clang++
else ifeq (${UNAME},Linux)
  export LLVM_ROOT:=/usr/lib/llvm-19
endif

.PHONY: all check test format clean distclean
all: .init
	cmake --workflow --preset dev --fresh

format:
	git ls-files ::*.cmake ::*CMakeLists.txt | xargs cmake-format -i
	git clang-format master

check: all
	run-clang-tidy -p build/dev -checks='-*,misc-header-*,misc-include-*' tests
	-ninja -C build/dev spell-check

test:
	cmake --preset ci-${hostSystemName}
	cmake --build build
	cmake --install build --prefix $(CURDIR)/stagedir
	cmake -G Ninja -B build/tests -S tests -D CMAKE_PREFIX_PATH=$(CURDIR)/stagedir
	cmake --build build/tests
	ctest --test-dir build/tests

.init: requirements.txt .CMakeUserPresets.json
	perl -p -e 's/<hostSystemName>/${hostSystemName}/;' .CMakeUserPresets.json > CMakeUserPresets.json
	-pip3 install --user --upgrade -r requirements.txt
	touch .init

clean:
	rm -rf build

distclean: clean
	rm -rf stagedir .init tags *.bak

GNUmakefile :: ;
*.txt :: ;
*.json :: ;

# Anything we don't know how to build will use this rule.
# The command is a do-nothing command.
#
% :: ;
