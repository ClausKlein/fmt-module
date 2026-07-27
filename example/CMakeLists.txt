# MRE: g++-16: error: unrecognized command-line option '-stdlib=libstdc++'
#
# usage:
#   cmake -S . -G Ninja -B build --fresh
#
# options
#   -D DISABLE_STDLIB_SET_ENV=YES
#   -D USE_STDLIB_OPTIONS=YES

cmake_minimum_required(VERSION 3.31...4.4)

if(CMAKE_VERSION VERSION_GREATER_EQUAL "4.4.0")
    set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
        "f35a9ac6-8463-4d38-8eec-5d6008153e7d"
    )
elseif(CMAKE_VERSION VERSION_GREATER_EQUAL "4.3.0")
    set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
        "451f2fe2-a8a2-47c3-bc32-94786d8fc91b"
    )
elseif(CMAKE_VERSION VERSION_GREATER_EQUAL "3.30.0")
    if(CMAKE_VERSION VERSION_LESS "3.31.8")
        set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
            "0e5b6991-d74f-4b3d-a41c-cf096e0b2508"
        )
    elseif(CMAKE_VERSION VERSION_LESS "4.0.0")
        set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
            "d0edc3af-4c50-42ea-a356-e2862fe7a444"
        )
    elseif(CMAKE_VERSION VERSION_LESS "4.0.3")
        set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
            "a9e1cf81-9932-4810-974b-6eccaf14e457"
        )
    elseif(CMAKE_VERSION VERSION_LESS "4.3.0")
        set(CMAKE_EXPERIMENTAL_CXX_IMPORT_STD
            "d0edc3af-4c50-42ea-a356-e2862fe7a444"
        )
    endif()
endif()

# PREVENT CMake Error in CMakeLists.txt:
#   The "CXX_MODULE_STD" property on target "main" requires toolchain support,
#   but it was not provided.  Reason:
#
#     Toolchain does not support discovering module metadata
if(NOT DISABLE_STDLIB_SET_ENV)
    set(ENV{CXX} "g++-16")
    set(ENV{CXXFLAGS} "-stdlib=libstdc++")
endif()

set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(CMAKE_CXX_MODULE_STD ON)
set(CMAKE_CXX_SCAN_FOR_MODULES ON)
set(CMAKE_SKIP_TEST_ALL_DEPENDENCY OFF)

##################################################
project("use_module_std" LANGUAGES CXX)
##################################################

if(NOT CMAKE_CXX_STANDARD)
    set(CMAKE_CXX_STANDARD 23)
endif()

set(CMAKE_CXX_STANDARD_REQUIRED YES)
set(CMAKE_CXX_EXTENSIONS NO)

if(USE_STDLIB_OPTIONS OR APPLE)
    if(ENV{CXXFLAGS} STREQUAL -stdlib=libstdc++)
        add_compile_options(-stdlib=libstdc++)
        add_link_options(-stdlib=libstdc++)
    endif()
endif()

file(
    WRITE ${PROJECT_BINARY_DIR}/main.cpp
    "
import std;

int main() {
    std::println(\"Hello modules!\");
    return 0;
}
"
)

enable_testing()

add_executable(main main.cpp)
target_compile_features(main PRIVATE cxx_std_${CMAKE_CXX_STANDARD})
add_test(NAME main COMMAND main)
