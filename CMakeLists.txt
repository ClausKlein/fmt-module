cmake_minimum_required(VERSION 3.25...3.31)

include(cmake/prelude.cmake)

project(fmt
        VERSION 11.1.1.1
        DESCRIPTION "A modern formatting library"
        HOMEPAGE_URL https://fmt.dev/11.0/
        LANGUAGES CXX
)

include(cmake/variables.cmake)

set(CMAKE_CXX_STANDARD 23)
set(CMAKE_CXX_EXTENSIONS OFF)
set(CMAKE_CXX_STANDARD_REQUIRED YES)

set(CMAKE_DEBUG_POSTFIX D)
set(CPPdefinitions)
set(HAS_STDLIB_MODULES)

option(FMT_SEPARATE_COMPILATION "build fmt lib too" ${PROJECT_IS_TOP_LEVEL})
option(FMT_USE_MODULES "Export a CXX_MODULE fmt if possible" ${PROJECT_IS_TOP_LEVEL})
option(FMT_IMPORT_STD "Import the module std" ${PROJECT_IS_TOP_LEVEL})

if(FMT_USE_MODULES)
  list(APPEND CPPdefinitions FMT_MODULE)
  # XXX NO! list(APPEND CPPdefinitions FMT_ATTACH_TO_GLOBAL_MODULE)
  # TODO: add_compile_options(-Wno-reserved-module-identifier -Wno-include-angled-in-module-purview)

  if(FMT_IMPORT_STD) # FIXME: clang++ only! AND $ENV{LLVM_ROOT})
    if(UNIX)
      if(DEFINED ENV{LLVM_ROOT})
        message(STATUS "LLVM_ROOT=$ENV{LLVM_ROOT}")
        set(LLVM_LIBC_SOURCE $ENV{LLVM_ROOT}/share/libc++/v1)
        if(CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.0)
          set(HAS_STDLIB_MODULES stdlib)
          set(CMAKE_CXX_MODULE_STD ON)
          set(CMAKE_CXX_COMPILER_IMPORT_STD 23)
          set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD ON)
        endif()
      endif()

      add_compile_options(-fexperimental-library)
      add_link_options(-lc++experimental)
      add_compile_options(-stdlib=libc++)
      add_link_options(-stdlib=libc++)

      list(APPEND CPPdefinitions FMT_IMPORT_STD)
    endif()

    message(STATUS "CMAKE_CXX_COMPILER_IMPORT_STD=${CMAKE_CXX_COMPILER_IMPORT_STD}")
  endif()

  message(STATUS "CPPdefinitions=${CPPdefinitions}")
else()
  set(CMAKE_VERIFY_INTERFACE_HEADER_SETS ${PROJECT_IS_TOP_LEVEL})
endif()

# ---- add dependency libraries ----

include(cmake/CPM.cmake)

# cmake-format: off
cpmaddpackage(
  NAME fmt
  GITHUB_REPOSITORY fmtlib/fmt
  GIT_TAG 11.1.1
  VERSION 11.1.1
  DOWNLOAD_ONLY YES
)
# cmake-format: on

# ---- Declare library ----

# TODO: only if needed (compare) and possible!
if(EXISTS ${fmt_SOURCE_DIR}/src/fmt.cc AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/module/fmt.cppm)
  configure_file(${fmt_SOURCE_DIR}/src/fmt.cc ${CMAKE_CURRENT_SOURCE_DIR}/module/fmt.cppm COPYONLY)
endif()

configure_file(${fmt_SOURCE_DIR}/src/format.cc ${CMAKE_CURRENT_SOURCE_DIR}/module/format.cc COPYONLY)
configure_file(${fmt_SOURCE_DIR}/src/os.cc ${CMAKE_CURRENT_SOURCE_DIR}/module/os.cc COPYONLY)
file(GLOB_RECURSE _fmt_all_sources "module/*.cc")

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
  # file(GLOB_RECURSE _fmt_all_sources "${fmt_SOURCE_DIR}/src/*.cc")

  add_library(fmt)
  add_library(fmt::fmt ALIAS fmt)
  target_sources(
    fmt PUBLIC FILE_SET public_headers TYPE HEADERS BASE_DIRS ${fmt_SOURCE_DIR}/include FILES ${_fmt_public_header}
  )

  target_compile_features(
    fmt INTERFACE "$<$<COMPILE_FEATURES:cxx_std_23>:cxx_std_23>" "$<$<NOT:$<COMPILE_FEATURES:cxx_std_23>>:cxx_std_20>"
  )

  target_compile_options(fmt PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>)

  if(FMT_USE_MODULES)
    target_compile_definitions(fmt PUBLIC ${CPPdefinitions})
    # cmake-format: off
    target_sources(fmt PUBLIC
        FILE_SET public_modules
        TYPE CXX_MODULES
        BASE_DIRS
            ${CMAKE_CURRENT_SOURCE_DIR}/module
        FILES
            ${CMAKE_CURRENT_SOURCE_DIR}/module/fmt.cppm
    )
    # cmake-format: on
  else()
    set(CMAKE_CXX_SCAN_FOR_MODULES OFF)
    target_compile_definitions(fmt PUBLIC ${CPPdefinitions})
    target_sources(fmt PUBLIC ${_fmt_all_sources})
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
