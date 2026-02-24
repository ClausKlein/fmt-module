# Standard stuff

.SUFFIXES:

MAKEFLAGS+= --no-builtin-rules  # Disable the built-in implicit rules.
# MAKEFLAGS+= --warn-undefined-variables        # Warn when an undefined variable is referenced.
# MAKEFLAGS+= --include-dir=$(CURDIR)/conan     # Search DIRECTORY for included makefiles (*.mk).

export hostSystemName=$(shell uname)

ifeq (${hostSystemName},Darwin)
	export LLVM_PREFIX:=$(shell brew --prefix llvm)
	export LLVM_DIR:=$(shell realpath ${LLVM_PREFIX})
  export PATH:=${LLVM_DIR}/bin:${PATH}

  export CMAKE_CXX_STDLIB_MODULES_JSON=${LLVM_DIR}/lib/c++/libc++.modules.json
  export CXX=clang++
  export LDFLAGS=-L$(LLVM_DIR)/lib/c++ -lc++abi # XXX -lc++ -lc++experimental
  export GCOV="llvm-cov gcov"

  ### TODO: to test g++-15:
  export GCC_PREFIX:=$(shell brew --prefix gcc)
  export GCC_DIR:=$(shell realpath ${GCC_PREFIX})

  # export CMAKE_CXX_STDLIB_MODULES_JSON=${GCC_DIR}/lib/gcc/current/libstdc++.modules.json
  # export CXX:=g++-15
  # export CXXFLAGS:=-stdlib=libstdc++
  # export GCOV="gcov"
else ifeq (${hostSystemName},Linux)
  export LLVM_DIR=/usr/lib/llvm-20
  export PATH:=${LLVM_DIR}/bin:${PATH}
  export CXX=clang++-20
endif

.PHONY: all check test example clean format distclean
all: .init
	cmake --workflow --preset dev

check: all
	run-clang-tidy -p build/dev -checks='-*,misc-header-*,misc-include-*' tests
	-ninja -C build/dev spell-check

test:
	# cmake --preset ci-${hostSystemName} --fresh
	# cmake --build build
	# cmake --install build --prefix $(CURDIR)/stagedir
	cmake -G Ninja -B build/tests -S tests -D CMAKE_PREFIX_PATH=$(CURDIR)/stagedir
	cmake --build build/tests -- -v -j 1
	ctest --test-dir build/tests

example:
	cmake -B build/example -S example -G Ninja
	cmake --build build/example -- -v
	ctest --test-dir build/example --verbose

.init: requirements.txt .CMakeUserPresets.json CMakeLists.txt GNUmakefile
	perl -p -e 's/<hostSystemName>/${hostSystemName}/;' .CMakeUserPresets.json > CMakeUserPresets.json
	-pip3 install --upgrade -r requirements.txt
	cmake --preset dev --fresh --log-level=VERBOSE
	ln -sf build/dev/compile_commands.json .
	touch .init

clean:
	rm -rf build

format:
	pre-commit autoupdate
	pre-commit run --all

distclean: clean
	rm -rf stagedir .init CMakeUserPresets.json tags compile_commands.json
	find . -name '*~' -delete
	# XXX NO! git clean -xdf

GNUmakefile :: ;
*.txt :: ;
*.json :: ;

# Anything we don't know how to build will use this rule.
% ::
	ninja -C build/dev $(@)
