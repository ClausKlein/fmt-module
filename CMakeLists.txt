# CMake 3.30 is required for C++23 `import std` support;
cmake_minimum_required(VERSION 3.30...4.3)

include(cmake/prelude.cmake)

#==================================================
project(
    fmt
    VERSION 12.1.0.2
    DESCRIPTION "A modern formatting library"
    HOMEPAGE_URL https://fmt.dev/12.0/
    LANGUAGES CXX
)
#==================================================

include(cmake/cxx-modules-rules.cmake)

option(BUILD_SHARED_LIBS "Build using shared libraries" NO)

include(cmake/variables.cmake)

# FIXME: to prevent -Winclude-angled-in-module-purview in fmt/os.h
# see /Users/clausklein/.cache/CPM/fmt/6226dc0d560c5dca8bcd81db09f7e2752ccb8cef/include/fmt/os.h:33
set(CPPdefinitions FMT_USE_FCNTL=0)

option(FMT_SEPARATE_COMPILATION "build fmt lib too" ${PROJECT_IS_TOP_LEVEL})

#XXX option(FMT_USE_MODULES "Export a CXX_MODULE fmt if possible" ${CMAKE_CXX_SCAN_FOR_MODULES})
option(FMT_IMPORT_STD "Import the module std" ${CMAKE_CXX_MODULE_STD})

if(CMAKE_GENERATOR STREQUAL "Ninja" AND FMT_USE_MODULES)
    list(APPEND CPPdefinitions FMT_MODULE)
    # FIXME: NO! list(APPEND CPPdefinitions FMT_ATTACH_TO_GLOBAL_MODULE)

    if(CMAKE_CXX_MODULE_STD)
        list(APPEND CPPdefinitions FMT_IMPORT_STD)
    endif()

    message(
        STATUS
        "CMAKE_CXX_COMPILER_IMPORT_STD=${CMAKE_CXX_COMPILER_IMPORT_STD}"
    )
    message(STATUS "CMAKE_CXX_SCAN_FOR_MODULES=${CMAKE_CXX_SCAN_FOR_MODULES}")
    message(STATUS "CMAKE_CXX_MODULE_STD=${CMAKE_CXX_MODULE_STD}")
    message(STATUS "CPPdefinitions=${CPPdefinitions}")
else()
    option(CMAKE_VERIFY_INTERFACE_HEADER_SETS "" ${PROJECT_IS_TOP_LEVEL})
endif()

# ---- add dependency libraries ----

include(cmake/CPM.cmake)

cpmaddpackage(
    NAME fmt
    GITHUB_REPOSITORY fmtlib/fmt
    GIT_TAG 12.1.0
    VERSION 12.1.0
    DOWNLOAD_ONLY ON
    # NO! PATCH_COMMAND git apply -p 1 ${CMAKE_CURRENT_SOURCE_DIR}/fmt.patch
)

# -----------------------------------------
# ---- Collect the fmt library sources ----
# -----------------------------------------

# TODO(CK): manually  apply the patch if needed (compare) and possible!
if(
    EXISTS ${fmt_SOURCE_DIR}/src/fmt.cc
    AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/module/fmt.cppm
)
    configure_file(
        ${fmt_SOURCE_DIR}/src/fmt.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/module/fmt.cppm
        COPYONLY
    )
endif()

configure_file(
    ${fmt_SOURCE_DIR}/src/format.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/module/format.cc
    COPYONLY
)
configure_file(
    ${fmt_SOURCE_DIR}/src/os.cc
    ${CMAKE_CURRENT_SOURCE_DIR}/module/os.cc
    COPYONLY
)

file(
    GLOB_RECURSE _fmt_all_sources
    CONFIGURE_DEPENDS
    RELATIVE ${CMAKE_CURRENT_LIST_DIR}
    module/*.cc
)

# -----------------------------------------
# -----------------------------------------

#
# build the fmt interface library
#
add_library(fmt-header-only INTERFACE)
add_library(fmt::fmt-header-only ALIAS fmt-header-only)

file(
    GLOB_RECURSE _fmt_public_header
    CONFIGURE_DEPENDS
    # NO! RELATIVE ${fmt_SOURCE_DIR}/include
    ${fmt_SOURCE_DIR}/include/fmt/*.h
)
target_sources(
    fmt-header-only
    INTERFACE
        FILE_SET HEADERS
            BASE_DIRS ${fmt_SOURCE_DIR}/include
            FILES ${_fmt_public_header}
)

target_compile_definitions(fmt-header-only INTERFACE FMT_HEADER_ONLY)
target_compile_features(fmt-header-only INTERFACE cxx_std_23)

# Unicode support requires compiling with /utf-8.
target_compile_options(
    fmt-header-only
    INTERFACE $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>
)

#
# build the fmt library
#
if(FMT_SEPARATE_COMPILATION)
    add_library(fmt)
    add_library(fmt::fmt ALIAS fmt)
    target_sources(
        fmt
        PUBLIC
            FILE_SET public_headers
                TYPE HEADERS
                BASE_DIRS ${fmt_SOURCE_DIR}/include
                FILES ${_fmt_public_header}
    )

    target_compile_definitions(fmt PUBLIC ${CPPdefinitions})
    target_compile_options(
        fmt
        PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>
    )
    target_compile_features(fmt INTERFACE cxx_std_23)

    if(FMT_USE_MODULES)
        message(STATUS "FMT_USE_MODULES=${FMT_USE_MODULES}")
        target_sources(
            fmt
            PUBLIC
                FILE_SET public_modules
                    TYPE CXX_MODULES
                    BASE_DIRS ${CMAKE_CURRENT_SOURCE_DIR}/module
                    FILES ${CMAKE_CURRENT_SOURCE_DIR}/module/fmt.cppm
        )
    else()
        message(WARNING "Missing or disabled support for CXX_MODULES!")
        target_sources(fmt PRIVATE ${_fmt_all_sources})
    endif()

    if(FMT_WARNINGS_AS_ERRORS AND FMT_DEVELOPER_MODE AND UNIX)
        target_compile_options(fmt PRIVATE -Werror)
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
