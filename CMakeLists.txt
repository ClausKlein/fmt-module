# CMake 3.30 is required for C++23 `import std` support;
cmake_minimum_required(VERSION 3.31...4.4)

option(
    CMAKE_CXX_SCAN_FOR_MODULES
    "Whether to scan C++ source files for module dependencies"
    ON
)

include(cmake/prelude.cmake)

#==================================================
project(
    fmt
    VERSION 12.2.0.3
    DESCRIPTION "A modern formatting library"
    HOMEPAGE_URL https://fmt.dev/12.0/
    LANGUAGES CXX
)
#==================================================

include(cmake/variables.cmake)

if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_EXTENSIONS OFF)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
endif()

set(CMAKE_DEBUG_POSTFIX D)
set(CMAKE_SKIP_TEST_ALL_DEPENDENCY OFF)

option(BUILD_SHARED_LIBS "Build using shared libraries" OFF)

option(
    FMT_MODULE
    "Export a CXX_MODULE fmt-module if possible"
    ${CMAKE_CXX_SCAN_FOR_MODULES}
)
option(FMT_IMPORT_STD "Import the module std" ${FMT_MODULE})

if(CMAKE_GENERATOR STREQUAL "Ninja" AND FMT_MODULE)
    list(APPEND CPPdefinitions FMT_MODULE)
    # FIXME: NO! list(APPEND CPPdefinitions FMT_ATTACH_TO_GLOBAL_MODULE)

    if(
        CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
        AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.0
    )
        if(APPLE)
            execute_process(
                OUTPUT_VARIABLE LLVM_PREFIX
                COMMAND brew --prefix llvm
                COMMAND_ECHO STDOUT
            )
            string(STRIP ${LLVM_PREFIX} LLVM_PREFIX)
        elseif(LINUX)
            set(LLVM_PREFIX $ENV{LLVM_DIR})
        endif()

        add_compile_options(-stdlib=libc++)
        add_link_options(-stdlib=libc++)
    elseif(
        CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
        AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 15.0
    )
        if(APPLE)
            add_compile_options(-stdlib=libstdc++)
            add_link_options(-stdlib=libstdc++)
        endif()
    endif()

    if(FMT_MODULE)
        # Tell CMake that we explicitly want `import std`.
        # This will initialize the property on all targets declared after this to 1
        if(${CMAKE_CXX_STANDARD} IN_LIST CMAKE_CXX_COMPILER_IMPORT_STD)
            set(CMAKE_CXX_MODULE_STD ON)
        else()
            set(CMAKE_CXX_MODULE_STD OFF)
        endif()

        if(CMAKE_CXX_MODULE_STD)
            list(APPEND CPPdefinitions FMT_IMPORT_STD)
        endif()
    endif()

    message(
        STATUS
        "CMAKE_CXX_COMPILER_IMPORT_STD=${CMAKE_CXX_COMPILER_IMPORT_STD}"
    )
    message(STATUS "CMAKE_CXX_SCAN_FOR_MODULES=${CMAKE_CXX_SCAN_FOR_MODULES}")
    message(STATUS "CMAKE_CXX_MODULE_STD=${CMAKE_CXX_MODULE_STD}")
    message(STATUS "CPPdefinitions=${CPPdefinitions}")
endif()

# ---- add dependency libraries ----

include(cmake/CPM.cmake)

cpmaddpackage(
    NAME fmt
    GITHUB_REPOSITORY fmtlib/fmt
    GIT_TAG 12.2.0
    VERSION 12.2.0
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

set_target_properties(
    fmt-header-only
    PROPERTIES VERIFY_INTERFACE_HEADER_SETS ${PROJECT_IS_TOP_LEVEL}
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
if(FMT_MODULE)
    add_library(fmt-module)
    add_library(fmt::fmt-module ALIAS fmt-module)
    target_compile_options(
        fmt-module
        PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>
    )

    # FIXME: workaround for CMake error:
    #   Target requires "CXX26" but CMake does not know the flags to enable it
    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
        target_compile_features(fmt-module PUBLIC cxx_std_23)
        target_compile_options(fmt-module PUBLIC /std:c++latest)
    else()
        target_compile_features(fmt-module PUBLIC cxx_std_26)
        # TODO(CK): target_compile_features(fmt-module PUBLIC cxx_std_${CMAKE_CXX_STANDARD})
    endif()

    message(STATUS "FMT_MODULE=${FMT_MODULE}")
    target_sources(
        fmt-module
        PUBLIC
            FILE_SET public_modules
                TYPE CXX_MODULES
                BASE_DIRS module
                FILES module/fmt.cppm
            FILE_SET HEADERS
                BASE_DIRS ${fmt_SOURCE_DIR}/include
                FILES ${_fmt_public_header}
    )
    target_compile_definitions(fmt-module PUBLIC ${CPPdefinitions})
    set_target_properties(
        fmt-module
        PROPERTIES VERIFY_INTERFACE_HEADER_SETS OFF
    )
    #NO! target_link_libraries(fmt-module PUBLIC fmt-header-only)

    if(FMT_WARNINGS_AS_ERRORS AND FMT_DEVELOPER_MODE AND UNIX)
        target_compile_options(fmt-module PRIVATE -Werror)
    endif()
else()
    add_library(fmt)
    add_library(fmt::fmt ALIAS fmt)
    message(WARNING "Missing or disabled support for FMT_MODULE!")
    target_sources(
        fmt
        PRIVATE ${_fmt_all_sources}
        PUBLIC
            FILE_SET HEADERS
                BASE_DIRS ${fmt_SOURCE_DIR}/include
                FILES ${_fmt_public_header}
    )
    target_compile_options(
        fmt
        PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>
    )
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
