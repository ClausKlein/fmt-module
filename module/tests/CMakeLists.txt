cmake_minimum_required(VERSION 3.30...4.3)

include(../../cmake/prelude.cmake)

project(fmt_module_examples LANGUAGES CXX)

if(PROJECT_IS_TOP_LEVEL)
    enable_testing()

    # Find the fmt package containing the function to build the module
    find_package(fmt 12.1.0.2 EXACT REQUIRED HINT ../../stagedir/lib)

    include(../../cmake/cxx-modules-rules.cmake)

    option(FMT_IMPORT_STD "Import the module std" ${CMAKE_CXX_MODULE_STD})

    message(STATUS "CMAKE_CXX_MODULE_STD=${CMAKE_CXX_MODULE_STD}")
    message(
        STATUS
        "CMAKE_CXX_COMPILER_IMPORT_STD=${CMAKE_CXX_COMPILER_IMPORT_STD}"
    )
endif()

# TODO: list(APPEND ALL_TESTS ../../tests/header-only-test.cc)
set(ALL_TESTS header-only-test)
message(STATUS "Module tests to be built: ${ALL_TESTS}")

foreach(_file ${ALL_TESTS})
    add_executable(module_${_file})
    target_sources(module_${_file} PRIVATE ../../tests/${_file}.cc)
    if(FMT_USE_MODULES)
        target_link_libraries(module_${_file} fmt::fmt)
        # FIXME: message(WARNING "Add to module_${_file} CPPdefinitions=${CPPdefinitions}")
        # FIXME: target_compile_definitions(module_${_file} PRIVATE ${CPPdefinitions})
    else()
        message(FATAL_ERROR "Missing or disabled support for CXX_MODULES!")
        return()

        # TODO(CK): target_link_libraries(module_${_file} fmt::fmt-header-only)
    endif()
    add_test(NAME module_${_file} COMMAND echo Test | ${_file})
endforeach()
