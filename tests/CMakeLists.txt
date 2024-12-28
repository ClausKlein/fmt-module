cmake_minimum_required(VERSION 3.30...3.31)

project(fmt_test LANGUAGES CXX)

include(../cmake/folders.cmake OPTIONAL)
include(../cmake/windows-set-path.cmake OPTIONAL)

# ---- Dependencies ----

if(PROJECT_IS_TOP_LEVEL)
  enable_testing()

  find_package(fmt 11.1.1.1 EXACT REQUIRED)
  include(../cmake/CPM.cmake)
endif()

# ---- Tests ----

if(EXISTS ${fmt_SOURCE_DIR}/test/header-only-test.cc AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/header-only-test.cc)
  configure_file(${fmt_SOURCE_DIR}/test/header-only-test.cc ${CMAKE_CURRENT_SOURCE_DIR}/header-only-test.cc COPYONLY)
endif()
add_executable(header-only-test header-only-test.cc)

# Build the stdlib module
function(add_stdlib_module NAME)
  add_library(${NAME})
  add_library(__CMAKE::CXX23 ALIAS ${NAME})
  # cmake-format: off
  target_sources(${NAME} PUBLIC
    FILE_SET CXX_MODULES
    BASE_DIRS ${LLVM_LIBC_SOURCE}
    FILES
      ${LLVM_LIBC_SOURCE}/std.cppm
      ${LLVM_LIBC_SOURCE}/std.compat.cppm
  )
  # cmake-format: on
  target_compile_features(${NAME} PUBLIC cxx_std_23)
  target_compile_definitions(${NAME} PUBLIC _LIBCPP_HAS_NO_LOCALIZATION)
  target_compile_options(${NAME} PRIVATE -Wno-reserved-module-identifier)
endfunction()

if(FMT_USE_MODULES)
  # Build the stdlib modules if possible
  # /usr/local/Cellar/llvm/19.1.6/share/libc++/v1/std.cppm
  # /usr/local/Cellar/llvm/19.1.6/share/libc++/v1/std.compat.cppm
  if(NOT CMAKE_CXX_COMPILER_IMPORT_STD AND ADD_STDLIB_MODULES)
    message(STATUS "ADD_STDLIB_MODULES=${ADD_STDLIB_MODULES}")
    add_stdlib_module(${ADD_STDLIB_MODULES})
  endif()
  target_link_libraries(header-only-test ${ADD_STDLIB_MODULES} fmt::fmt)
else()
  target_link_libraries(header-only-test fmt::fmt-header-only)
endif()

if(NOT PROJECT_IS_TOP_LEVEL)
  if(NOT DEFINED CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
  endif()

  # test if the targets are findable from the install prefix directory
  # NOTE: For an INTERFACE library and multi config generators, we may always use
  # the -C Debug config type instead of  $<CONFIG> to prevent problems! CK
  # cmake-format: off
  if(CMAKE_BUILD_TYPE STREQUAL Debug)
    add_test(
      NAME find-package-test
      COMMAND ${CMAKE_CTEST_COMMAND}
        --verbose
        --output-on-failure -C Debug
        --build-and-test
          "${CMAKE_SOURCE_DIR}/module/tests" "${CMAKE_CURRENT_BINARY_DIR}/find-package-test"
        --build-generator ${CMAKE_GENERATOR}
        --build-makeprogram ${CMAKE_MAKE_PROGRAM}
        --build-options
          "-DCMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
          "-DCMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}"
          "-DCMAKE_CXX_EXTENSIONS=${CMAKE_CXX_EXTENSIONS}"
          "-DCMAKE_CXX_STANDARD_REQUIRED=${CMAKE_CXX_STANDARD_REQUIRED}"
          "-DCMAKE_BUILD_TYPE=Debug"
          "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
          "-DCMAKE_CXX_MODULE_STD=ON"
          "-DCMAKE_EXPERIMENTAL_CXX_IMPORT_STD=0e5b6991-d74f-4b3d-a41c-cf096e0b2508"
    )
  endif()
  # cmake-format: on
endif()

# ---- Setup strict Compiler Warnings ----

add_test(NAME header-only-test COMMAND header-only-test)

# ---- End-of-file commands ----

if(NOT PROJECT_IS_TOP_LEVEL)
  add_folders(Tests)
endif()
