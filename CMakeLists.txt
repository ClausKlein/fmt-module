cmake_minimum_required(VERSION 3.25...3.31)

include(cmake/prelude.cmake)

project(fmt
        VERSION 11.0.2.1
        DESCRIPTION "A modern formatting library"
        HOMEPAGE_URL https://fmt.dev/11.0/
        LANGUAGES CXX
)

include(cmake/variables.cmake)

set(CPPdefinitions)

set(CMAKE_VERIFY_INTERFACE_HEADER_SETS ${PROJECT_IS_TOP_LEVEL})
set(CMAKE_DEBUG_POSTFIX D)

# TODO: option(FMT_SEPARATE_COMPILATION "build fmt lib too" ${PROJECT_IS_TOP_LEVEL})
option(FMT_USE_MODULES "Export a CXX_MODULE asio if possible" OFF)
option(FMT_IMPORT_STD "Import the CXX_MODULE std if possible" OFF)

# ---- add dependency libraries ----

include(cmake/CPM.cmake)

# cmake-format: off
cpmaddpackage(
  NAME fmt
  GITHUB_REPOSITORY fmtlib/fmt
  GIT_TAG 11.0.2
  VERSION 11.0.2
  DOWNLOAD_ONLY YES
)
# cmake-format: on

# ---- Declare library ----

# TODO: only if needed (compare) and possible!
if(EXISTS ${fmt_SOURCE_DIR}/src/fmt.cc AND NOT EXISTS ${PROJECT_SOURCE_DIR}/module/fmt.cppm)
  configure_file(${fmt_SOURCE_DIR}/src/fmt.cc ${PROJECT_SOURCE_DIR}/module/fmt.cppm COPYONLY)
endif()

# fmt interface library
add_library(fmt-header-only INTERFACE)
add_library(fmt::fmt-header-only ALIAS fmt-header-only)

file(GLOB_RECURSE _fmt_public_header "${fmt_SOURCE_DIR}/include/fmt/*.h")
target_sources(
  fmt-header-only INTERFACE FILE_SET HEADERS BASE_DIRS ${fmt_SOURCE_DIR}/include FILES ${_fmt_public_header}
)

target_compile_definitions(fmt-header-only INTERFACE FMT_HEADER_ONLY)
target_compile_features(
  fmt-header-only INTERFACE "$<$<COMPILE_FEATURES:cxx_std_23>:cxx_std_23>"
                            "$<$<NOT:$<COMPILE_FEATURES:cxx_std_23>>:cxx_std_20>"
)

# Unicode support requires compiling with /utf-8.
target_compile_options(fmt-header-only INTERFACE $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>)

if(FMT_SEPARATE_COMPILATION)
  file(GLOB_RECURSE _fmt_all_sources "${fmt_SOURCE_DIR}/src/*.cc")
  set(_fmt_sources ${fmt_SOURCE_DIR}/src/fmt.cc)

  add_library(fmt)
  add_library(fmt::fmt ALIAS fmt)
  target_sources(
    fmt PUBLIC FILE_SET public_headers TYPE HEADERS BASE_DIRS ${fmt_SOURCE_DIR}/include FILES ${_fmt_public_header}
  )

  target_compile_features(
    fmt INTERFACE "$<$<COMPILE_FEATURES:cxx_std_23>:cxx_std_23>" "$<$<NOT:$<COMPILE_FEATURES:cxx_std_23>>:cxx_std_20>"
  )

  if(FMT_USE_MODULES)
    target_compile_definitions(fmt PUBLIC USE_MODULES ${CPPdefinitions})
    # cmake-format: off
    target_sources(fmt PUBLIC
        FILE_SET public_modules
        TYPE CXX_MODULES
        BASE_DIRS ${PROJECT_SOURCE_DIR}
        FILES
            ${PROJECT_SOURCE_DIR}/module/fmt.cppm
    )
    # cmake-format: on
  else()
    target_compile_definitions(fmt PUBLIC FMT_SEPARATE_COMPILATION ${CPPdefinitions})
    target_sources(fmt PUBLIC ${_fmt_sources})
  endif()

  if(FMT_WARNINGS_AS_ERRORS AND FMT_DEVELOPER_MODE AND UNIX)
    target_compile_options(fmt PUBLIC -Werror)
  endif()
endif()

# ---- Install rules ----

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(cmake/install-rules.cmake)
endif()

# ---- Developer mode ----

if(NOT FMT_DEVELOPER_MODE)
  return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
  message(AUTHOR_WARNING "Developer mode is intended for developers of fmt")
endif()

include(cmake/dev-mode.cmake)
