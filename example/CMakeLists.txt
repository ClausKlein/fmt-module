# CMake 3.30 is required for C++23 `import std` support; we use 4.x
# here so that in-development versions satisfy it.
#
# from https://www.kitware.com/import-std-in-cmake-3-30/
#
cmake_minimum_required(VERSION 4.0...4.4)

# Set experimental flag to enable `import std` support from CMake.
# This must be enabled before C++ language support.
# set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD # This specific value changes as experimental support evolves. See
#     # `Help/dev/experimental.rst` in the CMake source corresponding to
#     # your CMake build for the exact value to use.
#     "a9e1cf81-9932-4810-974b-6eccaf14e457"
# )
set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD "d0edc3af-4c50-42ea-a356-e2862fe7a444")

# C++ needs to be enabled.
project(import_std LANGUAGES CXX)

# Tell CMake that we explicitly want `import std`. This will initialize the
# property on all targets declared after this to 1
set(CMAKE_CXX_MODULE_STD 1)

# Make a library.
add_library(uses_std STATIC)
# Add sources.
target_sources(uses_std PRIVATE uses_std.cxx)
# Tell CMake we're using C++23 but only C++20 is needed to consume it.
target_compile_features(uses_std PRIVATE cxx_std_26 INTERFACE cxx_std_20)

# Make an executable.
add_executable(main)
# Note that this source is *not* allowed to `import std` as it ends up
# with only C++20 support due to the `uses_std` INTERFACE requirements.
target_sources(main PRIVATE main.cxx)
target_link_libraries(main PRIVATE uses_std)

enable_testing()
add_test(NAME main COMMAND main)
