# Standard stuff

.SUFFIXES:

MAKEFLAGS+= --no-builtin-rules  # Disable the built-in implicit rules.
MAKEFLAGS+= --warn-undefined-variables        # Warn when an undefined variable is referenced.

export hostSystemName:=$(shell uname)

ifeq (${hostSystemName},Darwin)
  export LLVM_PREFIX:=$(shell brew --prefix llvm)
  export LLVM_DIR:=$(shell realpath ${LLVM_PREFIX})
  export PATH:=${LLVM_DIR}/bin:${PATH}

  export CMAKE_CXX_STDLIB_MODULES_JSON:=${LLVM_DIR}/lib/c++/libc++.modules.json
  export CXX:=clang++
  export LDFLAGS:=-L$(LLVM_DIR)/lib/c++ -lc++abi # -lc++ ## -lc++experimental
  export GCOV:="llvm-cov gcov"

  ### TODO: to test g++-16:
  export GCC_PREFIX:=$(shell brew --prefix gcc)
  export GCC_DIR:=$(shell realpath ${GCC_PREFIX})

  # export CMAKE_CXX_STDLIB_MODULES_JSON:=${GCC_DIR}/lib/gcc/current/libstdc++.modules.json
  # export CXX:=g++-16
  # export CXXFLAGS:=-stdlib=libstdc++
  # export GCOV:="gcov"
else ifeq (${hostSystemName},Linux)
	export LLVM_DIR:=/usr/lib/llvm-22
  export PATH:=${LLVM_DIR}/bin:${PATH}
  export CXX:=clang++-22
endif

.PHONY: all check test format clean distclean
all: .init
	cmake --workflow --preset dev
	#XXX cmake --build --preset dev --target all_verify_interface_header_sets

format: distclean
	codespell -w
	git ls-files ::*CMakeLists.txt ::*.cmake ::*.cmake.in | xargs gersemi -i
	git ls-files ::*.cxx ::*.cpp ::*.hpp ::*.cppm  ::*.json | xargs clang-format -i

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
		-D CMAKE_CXX_SCAN_FOR_MODULES=1 -D CMAKE_CXX_MODULE_STD=1 -D CMAKE_BUILD_TYPE=Release \
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
	rm -rf stagedir .cache .init CMakeUserPresets.json compile_commands.json tags *.bak *~ .*~

GNUmakefile :: ;
*.txt :: ;
*.json :: ;

# Anything we don't know how to build will use this rule.
% ::
	ninja -C build/dev $(@)
