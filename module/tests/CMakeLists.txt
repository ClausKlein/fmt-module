cmake_minimum_required(VERSION 3.30...3.31)

project(fmt_moddule_examples LANGUAGES CXX)

if(PROJECT_IS_TOP_LEVEL)
  enable_testing()

  # Find the fmt package containing the function to build the module
  find_package(fmt 11.1.1.1 EXACT REQUIRED HINT ../../stagedir/lib)

  # Use modules?
  unset(USE_MODULES)
  if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 23)
    set(CMAKE_CXX_EXTENSIONS ON)
    set(CMAKE_CXX_STANDARD_REQUIRED ON)
  endif()
  if(CMAKE_GENERATOR STREQUAL "Ninja")
    if(CMAKE_CXX_COMPILER_ID STREQUAL "Clang" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 18.0)
      set(USE_MODULES ON)
      # see https://releases.llvm.org/15.0.0/projects/libcxx/docs/ReleaseNotes.html
      # Always use libc++
      add_compile_options(-fexperimental-library)
      add_link_options(-lc++experimental)
      add_compile_options(-stdlib=libc++)
      add_link_options(-stdlib=libc++)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "GNU" AND CMAKE_CXX_COMPILER_VERSION VERSION_GREATER_EQUAL 14.0)
      set(USE_MODULES ON)
    elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
      set(USE_MODULES ON)
    endif()
    message(STATUS "CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES=${CMAKE_CXX_IMPLICIT_INCLUDE_DIRECTORIES}")
  endif()
  if(USE_MODULES)
    # Build the fmt module
    add_fmt_module(fmt_module)
  endif()
endif()

# TODO: list(APPEND ALL_TESTS ../../tests/header-only-test.cc)
set(ALL_TESTS header-only-test)
message(STATUS "Module tests to be built: ${ALL_TESTS}")

foreach(_file ${ALL_TESTS})
  add_executable(module_${_file})
  target_sources(module_${_file} PRIVATE ../../tests/${_file}.cc)
  if(USE_MODULES)
    target_link_libraries(module_${_file} fmt_module)
    #XXX target_compile_definitions(module_${_file} PUBLIC USE_MODULES)
  else()
    target_link_libraries(module_${_file} fmt::fmt-header-only)
  endif()
  add_test(NAME module_${_file} COMMAND echo Test | ${_file})
endforeach()
