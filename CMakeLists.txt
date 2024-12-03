cmake_minimum_required(VERSION 3.25...3.31)

include(cmake/prelude.cmake)

project(fmt
        VERSION 11.0.2.1
        DESCRIPTION "A modern formatting library"
        HOMEPAGE_URL https://fmt.dev/11.0/
        LANGUAGES CXX
)

include(cmake/variables.cmake)

set(CPPdefinitions FMT_HEADER_ONLY)

# if(PROJECT_IS_TOP_LEVEL)
#   include(CheckCXXSymbolExists)
#   check_cxx_symbol_exists(snprintf cstdio FMT_HAS_SNPRINTF)
#   check_cxx_symbol_exists(sprintf_s cstdio FMT_HAS_SECURE_RTL)
# endif()
#
# set(CPPdefinitions FMT_NO_DEPRECATED FMT_DISABLE_BOOST_CONTEXT_FIBER)
# if(FMT_HAS_SECURE_RTL)
#   list(APPEND CPPdefinitions FMT_HAS_SECURE_RTL)
# elseif(FMT_HAS_SNPRINTF)
#   list(APPEND CPPdefinitions FMT_HAS_SNPRINTF)
# endif()

set(CMAKE_VERIFY_INTERFACE_HEADER_SETS ${PROJECT_IS_TOP_LEVEL})
# XXX option(FMT_SEPARATE_COMPILATION "build fmt lib too" ${PROJECT_IS_TOP_LEVEL})
set(CMAKE_DEBUG_POSTFIX D)

# ---- add dependency libraries ----

include(cmake/CPM.cmake)

cpmaddpackage(
  NAME
  fmt
  GITHUB_REPOSITORY
  fmtlib/fmt
  GIT_TAG
  11.0.2
  VERSION
  11.0.2
  DOWNLOAD_ONLY
  YES
)

# ---- Declare library ----

configure_file(${fmt_SOURCE_DIR}/src/fmt.cc ${fmt_SOURCE_DIR}/module/fmt.cppm COPYONLY)
file(GLOB_RECURSE _fmt_implementation "${fmt_SOURCE_DIR}/include/fmt/*.h")

# fmt interface library
add_library(fmt_header INTERFACE)
add_library(fmt::fmt_header ALIAS fmt_header)
target_sources(fmt_header INTERFACE FILE_SET HEADERS BASE_DIRS ${fmt_SOURCE_DIR}/include FILES ${_fmt_implementation})

target_compile_definitions(fmt_header INTERFACE ${CPPdefinitions})
target_compile_features(
  fmt_header INTERFACE "$<$<COMPILE_FEATURES:cxx_std_23>:cxx_std_23>"
                       "$<$<NOT:$<COMPILE_FEATURES:cxx_std_23>>:cxx_std_20>"
)

if(MSVC)
  # Unicode support requires compiling with /utf-8.
  target_compile_options(fmt_header INTERFACE $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>)
endif()

if(FMT_SEPARATE_COMPILATION)
  set(_libfmt_SOURCES src/fmt.cpp)

  if(OpenSSL_FOUND)
    list(APPEND _libfmt_SOURCES src/fmt_ssl.cpp)
  endif()

  file(GLOB_RECURSE _fmt_headers "include/fmt/*.hpp")
  list(FILTER _fmt_headers EXCLUDE REGEX [=[.*/experimental/.*\.hpp]=])
  list(FILTER _fmt_headers EXCLUDE REGEX [=[.*/spawn.*\.hpp]=])

  # FIXME: some header in include/fmt/detail fails CMAKE_VERIFY_INTERFACE_HEADER_SETS!
  # NOTE: we need them installed, but we used them install with fmt_header INTERFACE! CK
  set(_public_headers include/fmt.hpp ${_fmt_headers})
  list(FILTER _public_headers EXCLUDE REGEX [=[.*/detail/.*\.hpp]=])
  list(FILTER _public_headers EXCLUDE REGEX [=[.*/impl/.*\.hpp]=])
  list(FILTER _public_headers EXCLUDE REGEX [=[.*/spawn.*\.hpp]=])
  # foreach(header in LISTS ${_public_headers})
  #   message(INFO "${header}")
  # endforeach()

  add_library(fmt ${_libfmt_SOURCES})
  add_library(fmt::fmt ALIAS fmt)
  target_sources(fmt PUBLIC FILE_SET public_headers TYPE HEADERS BASE_DIRS include FILES ${_public_headers})

  target_compile_definitions(fmt PUBLIC FMT_SEPARATE_COMPILATION ${CPPdefinitions})
  target_link_libraries(fmt PUBLIC Threads::Threads)
  target_compile_features(
    fmt INTERFACE "$<$<COMPILE_FEATURES:cxx_std_23>:cxx_std_23>" "$<$<NOT:$<COMPILE_FEATURES:cxx_std_23>>:cxx_std_20>"
  )

  if(FMT_WARNINGS_AS_ERRORS AND FMT_DEVELOPER_MODE AND UNIX)
    target_compile_options(fmt PUBLIC -Werror)
  endif()

  if(OpenSSL_FOUND)
    target_link_libraries(fmt PUBLIC OpenSSL::SSL OpenSSL::Crypto)
  endif()
endif()

# ---- Install rules ----

if(NOT CMAKE_SKIP_INSTALL_RULES)
  include(cmake/AddUninstallTarget.cmake)
  include(cmake/install-rules.cmake)
  install(FILES module/fmt.cppm DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/fmt/module)
endif()

# ---- Developer mode ----

if(NOT FMT_DEVELOPER_MODE)
  return()
elseif(NOT PROJECT_IS_TOP_LEVEL)
  message(AUTHOR_WARNING "Developer mode is intended for developers of fmt")
endif()

include(cmake/dev-mode.cmake)
