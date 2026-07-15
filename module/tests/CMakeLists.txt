cmake_minimum_required(VERSION 3.30...4.4)

project(fmt_moddule_examples LANGUAGES CXX)

set(USE_MODULES ON)

if(PROJECT_IS_TOP_LEVEL)
    enable_testing()

    # Find the fmt package containing the function to build the module
    find_package(fmt 12.2.0.2 EXACT REQUIRED HINT ../../stagedir/lib)

    # Use modules?
    unset(USE_MODULES)

    if(NOT CMAKE_CXX_STANDARD)
        set(CMAKE_CXX_STANDARD 26)
        set(CMAKE_CXX_EXTENSIONS OFF)
        set(CMAKE_CXX_STANDARD_REQUIRED ON)
        set(CMAKE_CXX_SCAN_FOR_MODULES ON)
    endif()

    if(CMAKE_GENERATOR STREQUAL "Ninja")
        if(
            CMAKE_CXX_COMPILER_ID STREQUAL "Clang"
            AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 19.0
        )
            set(USE_MODULES ON)
            # see https://releases.llvm.org/15.0.0/projects/libcxx/docs/ReleaseNotes.html
            # Always use libc++
            # add_link_options(-L${LLVM_DIR}/lib/c++)
            add_compile_options(-stdlib=libc++)
            add_link_options(-stdlib=libc++)
        elseif(
            CMAKE_CXX_COMPILER_ID STREQUAL "GNU"
            AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 15.0
        )
            set(USE_MODULES ON)
            add_compile_options(-stdlib=libstdc++)
            add_link_options(-stdlib=libstdc++)
        elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
            set(USE_MODULES ON)
        endif()
        message(
            STATUS
            "CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES=${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}"
        )
    endif()
endif()

message(STATUS "CMAKE_CXX_MODULE_STD=${CMAKE_CXX_MODULE_STD}")
message(STATUS "CMAKE_CXX_COMPILER_IMPORT_STD=${CMAKE_CXX_COMPILER_IMPORT_STD}")

set(ALL_TESTS module-test)
message(STATUS "Module tests to be built: ${ALL_TESTS}")

foreach(_file ${ALL_TESTS})
    add_executable(module_${_file})
    target_sources(module_${_file} PRIVATE ${_file}.cc)

    if(USE_MODULES)
        target_link_libraries(module_${_file} fmt::fmt)
    else()
        message(FATAL_ERROR "Missing or disabled support for CXX_MODULES!")
        return()
    endif()

    add_test(NAME module_${_file} COMMAND echo Test | ${_file})
endforeach()
