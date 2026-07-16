# Standard stuff

.SUFFIXES:

MAKEFLAGS+= --no-builtin-rules  # Disable the built-in implicit rules.
MAKEFLAGS+= --warn-undefined-variables  # Warn when an undefined variable is referenced.

# TODO: export CMAKE_CXX_COMPILER_LAUNCHER=ccache
# TODO: export CMAKE_C_COMPILER_LAUNCHER=ccache
export CMAKE_CONFIG_TYPE=Release
export CMAKE_CONFIGURATION_TYPES="Release;Debug"
export CMAKE_EXPORT_COMPILE_COMMANDS=YES
export CMAKE_GENERATOR=Ninja
# XXX export CMAKE_INSTALL_PREFIX="${HOME}/.local"
# XXX export CMAKE_PREFIX_PATH="${HOME}/.local"

# NOTE: only to use experimental cmake versions:
# TODO: export PATH="${HOME}/.local/bin:${PATH}"

export hostSystemName:=$(shell uname)

ifeq (${hostSystemName},Darwin)

  ### NOTE: to test clang++-22:
  ifeq (${CXX},clang++)
    STDLIB:=libc++
    SYSROOT:=$(shell xcrun --show-sdk-path)
    export LLVM_PREFIX:=$(shell brew --prefix llvm)
    export LLVM_DIR:=$(shell realpath ${LLVM_PREFIX})
    export PATH:=${LLVM_DIR}/bin:${PATH}
    export CMAKE_CXX_STDLIB_MODULES_JSON:=${LLVM_DIR}/lib/c++/$(STDLIB).modules.json
    export CXXFLAGS:=-stdlib=$(STDLIB) --sysroot=$(SYSROOT)
    export LDFLAGS:=-L$(LLVM_DIR)/lib/c++ # XXX -lc++abi
    # XXX export CXX:=clang++
    # XXX export GCOV:="llvm-cov gcov"
  endif

  ### NOTE: to test g++-16:
  ifeq (${CXX},g++-16)
    STDLIB:=libstdc++
    export GCC_PREFIX:=$(shell brew --prefix gcc)
    export GCC_DIR:=$(shell realpath ${GCC_PREFIX})
    export CMAKE_CXX_STDLIB_MODULES_JSON:=${GCC_DIR}/lib/gcc/current/$(STDLIB).modules.json
    export CXXFLAGS:=-stdlib=$(STDLIB)
    # XXX export CXX:=g++-16
    # XXX export GCOV:="gcov"
  endif

else ifeq (${hostSystemName},Linux)
  # clang++ -print-file-name=libc++.modules.json
  # /lib/x86_64-linux-gnu/libc++.modules.json
  # /usr/lib/llvm-23/lib/libc++.modules.json -> ../../x86_64-linux-gnu/libc++.modules.json
  # /usr/lib/llvm-23/share/libc++/v1/std.compat.cppm
  # /usr/lib/llvm-23/share/libc++/v1/std.cppm
  # QUICKFIX: /lib/share -> /usr/lib/llvm-23/share
  STDLIB:=libc++
  export LLVM_DIR:=/usr/lib/llvm-23
  export PATH:=${LLVM_DIR}/bin:${PATH}
  export CXX:=clang++-23
  export CXXFLAGS:=-stdlib=$(STDLIB)
  export LDFLAGS:=-L$(LLVM_DIR)/lib/c++ # XXX -lc++abi
  export CMAKE_CXX_STDLIB_MODULES_JSON:=$(shell clang++-23 -print-file-name=libc++.modules.json)
  # export CMAKE_CXX_STDLIB_MODULES_JSON:=${LLVM_DIR}/lib/c++/$(STDLIB).modules.json
endif

.PHONY: all check test format clean distclean
all: .init
	cmake --workflow --preset dev
	#XXX cmake --build --preset dev --target all_verify_interface_header_sets

format: distclean
	codespell -w
	git ls-files ::*CMakeLists.txt ::*.cmake ::*.cmake.in | xargs gersemi -i
	git ls-files ::*.c ::*.h ::*.cc ::*.hh ::*.cxx ::*.cpp ::*.hpp ::*.cppm ::*.json | xargs clang-format -i

check: .init
	run-clang-tidy -p build/dev -checks='-*,misc-header-*,misc-include-*' \
		$(CURDIR)/tests \
		#TODO: $(CURDIR)/module
	-ninja -C build/dev spell-check

test:
	# cmake --preset ci-${hostSystemName} --fresh
	# cmake --build build
	# cmake --install build --prefix $(CURDIR)/stagedir
	cmake -G Ninja -B build/tests -S tests --fresh \
		-D CMAKE_CXX_STDLIB_MODULES_JSON=${CMAKE_CXX_STDLIB_MODULES_JSON} \
		-D CMAKE_CXX_SCAN_FOR_MODULES=1 -D CMAKE_CXX_MODULE_STD=1 -D CMAKE_BUILD_TYPE=Debug \
		-D CMAKE_PREFIX_PATH=$(CURDIR)/stagedir
	cmake --build build/tests -- -v -j 1
	ctest --test-dir build/tests

.init: requirements.txt .CMakeUserPresets.json CMakePresets.json CMakeLists.txt GNUmakefile
	perl -p -e 's/<hostSystemName>/${hostSystemName}/;' .CMakeUserPresets.json > CMakeUserPresets.json
	#XXX -pip3 install --upgrade -r requirements.txt
	cmake --preset dev -D CMAKE_CXX_SCAN_FOR_MODULES=ON -D FMT_USE_MODULES==ON --fresh --log-level=VERBOSE
	ln -sf build/dev/compile_commands.json .
	touch .init

clean:
	rm -rf build

distclean: clean
	rm -rf stagedir .cache .init CMakeUserPresets.json compile_commands.json tags *.bak .*~
	find . -name '*~' -delete

GNUmakefile :: ;
*.txt :: ;
*.json :: ;

# Anything we don't know how to build will use this rule.
% ::
	ninja -C build/dev $(@)
