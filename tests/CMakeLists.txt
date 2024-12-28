cmake_minimum_required(VERSION 3.25...3.31)

project(fmt_test LANGUAGES CXX)

include(../cmake/folders.cmake OPTIONAL)
include(../cmake/windows-set-path.cmake OPTIONAL)

# ---- Dependencies ----

if(PROJECT_IS_TOP_LEVEL)
  enable_testing()

  find_package(fmt 11.1.0.2 EXACT REQUIRED)
  include(../cmake/CPM.cmake)
endif()

# cmake-format: off
cpmaddpackage(
  NAME googletest
  GITHUB_REPOSITORY google/googletest
  GIT_TAG v1.15.2
  VERSION 1.15.2
  EXCLUDE_FROM_ALL YES
  OPTIONS "INSTALL_GTEST OFF" "gtest_force_shared_crt"
)
# cmake-format: on

# ---- Tests ----

if(NOT TARGET GTest::gtest)
  message(WARNING "Missing alias for gtest!")
  add_library(GTest::gtest ALIAS gtest)
endif()

if(EXISTS ${fmt_SOURCE_DIR}/test/header-only-test.cc AND NOT EXISTS ${PROJECT_SOURCE_DIR}/header-only-test.cc)
  configure_file(${fmt_SOURCE_DIR}/test/header-only-test.cc ${PROJECT_SOURCE_DIR}/header-only-test.cc COPYONLY)
endif()
add_executable(header-only-test header-only-test.cc)

if(FMT_USE_MODULES)
  target_link_libraries(header-only-test fmt::fmt)
else()
  target_link_libraries(header-only-test fmt::fmt-header-only)
endif()

if(NOT PROJECT_IS_TOP_LEVEL)
  if(NOT DEFINED CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
  endif()

  # test if the targets are findable from the build directory
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
          "-DCMAKE_BUILD_TYPE=Debug"
          "-DCMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
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
