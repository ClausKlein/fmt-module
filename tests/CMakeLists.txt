cmake_minimum_required(VERSION 3.30...4.2)

project(fmt_test LANGUAGES CXX)

include(../cmake/folders.cmake OPTIONAL)
include(../cmake/windows-set-path.cmake OPTIONAL)

# ---- Dependencies ----

if(PROJECT_IS_TOP_LEVEL)
    enable_testing()

    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_EXTENSIONS ON)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
    set(CMAKE_CXX_SCAN_FOR_MODULES ON)

    find_package(fmt 12.1.0.1 EXACT REQUIRED HINT ../stagedir/lib)

    #XXX add_subdirectory(.. fmt_module)
endif()

# -------------------------------------------
# -- OPTIONAL: Collect the fmt test sources --
# -------------------------------------------
if(
    EXISTS ${fmt_SOURCE_DIR}/test/header-only-test.cc
    AND NOT EXISTS ${CMAKE_CURRENT_SOURCE_DIR}/header-only-test.cc
)
    configure_file(
        ${fmt_SOURCE_DIR}/test/header-only-test.cc
        ${CMAKE_CURRENT_SOURCE_DIR}/header-only-test.cc
        COPYONLY
    )
endif()

# ---- Tests ----

add_executable(header-only-test header-only-test.cc)

if(CMAKE_CXX_SCAN_FOR_MODULES)
    if(TARGET fmt::fmt)
        target_link_libraries(header-only-test fmt::fmt)
        # FIXME: message(WARNING "Add to header-only-test CPPdefinitions=${CPPdefinitions}")
        # FIXME: target_compile_definitions(header-only-test PRIVATE ${CPPdefinitions})
    else()
        message(FATAL_ERROR "NOT TARGET fmt::fmt!")
        target_link_libraries(header-only-test fmt::fmt)
    endif()
else()
    message(WARNING "Missing or disabled support for CXX_MODULES!")
    target_link_libraries(header-only-test fmt::fmt-header-only)
endif()

if(NOT DEFINED CMAKE_PREFIX_PATH)
    set(CMAKE_PREFIX_PATH ${CMAKE_INSTALL_PREFIX})
endif()

# test if the targets are findable from the install prefix directory
# NOTE: For an INTERFACE library and multi config generators, we may always use
# the -C Release config type instead of $<CONFIG> to prevent problems! CK
# gersemi: off
if(CMAKE_BUILD_TYPE STREQUAL Release)
    add_test(
        NAME find-package-test
        COMMAND
            ${CMAKE_CTEST_COMMAND} -C Release --build-and-test
            "${CMAKE_SOURCE_DIR}/module/tests"
            "${CMAKE_CURRENT_BINARY_DIR}/find-package-test"
            --build-generator ${CMAKE_GENERATOR}
            --build-makeprogram ${CMAKE_MAKE_PROGRAM}
            --build-options
            "-D CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}"
            "-D CMAKE_CXX_STANDARD=${CMAKE_CXX_STANDARD}"
            "-D CMAKE_CXX_EXTENSIONS=${CMAKE_CXX_EXTENSIONS}"
            "-D CMAKE_CXX_STANDARD_REQUIRED=${CMAKE_CXX_STANDARD_REQUIRED}"
            "-D CMAKE_BUILD_TYPE=Release"
            "-D CMAKE_PREFIX_PATH=${CMAKE_PREFIX_PATH}"
            "-D CPPdefinitions=${CPPdefinitions}"
            "-D CMAKE_CXX_MODULE_STD=${CMAKE_CXX_MODULE_STD}"
            "-D CMAKE_CXX_SCAN_FOR_MODULES=${CMAKE_CXX_SCAN_FOR_MODULES}"
            "-D CMAKE_CXX_STDLIB_MODULES_JSON=${CMAKE_CXX_STDLIB_MODULES_JSON}"
            "-D CMAKE_EXPERIMENTAL_CXX_IMPORT_STD=${CMAKE_EXPERIMENTAL_CXX_IMPORT_STD}"
    )
endif()
# gersemi: on

# ---- Setup strict Compiler Warnings ----

add_test(NAME header-only-test COMMAND header-only-test)

# ---- End-of-file commands ----

if(NOT PROJECT_IS_TOP_LEVEL)
    add_folders(Tests)
endif()
