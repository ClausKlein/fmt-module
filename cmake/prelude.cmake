# ---- In-source guard ----

if(CMAKE_SOURCE_DIR STREQUAL CMAKE_BINARY_DIR)
    message(
        FATAL_ERROR
        "In-source builds are not supported. "
        "Please read the BUILDING document before trying to build this project. "
        "You may need to delete 'CMakeCache.txt' and 'CMakeFiles/' first."
    )
endif()

# -- Use ccache if found --
find_program(CCACHE_EXECUTABLE "ccache" HINTS /usr/local/bin /opt/local/bin)
if(CCACHE_EXECUTABLE)
    message(STATUS "use ccache")
    set(CMAKE_CXX_COMPILER_LAUNCHER
        "${CCACHE_EXECUTABLE}"
        CACHE PATH
        "ccache"
        FORCE
    )
    set(CMAKE_C_COMPILER_LAUNCHER
        "${CCACHE_EXECUTABLE}"
        CACHE PATH
        "ccache"
        FORCE
    )
endif()

# Set experimental flag to enable `import std` support from CMake.
# This must be enabled before C++ language support.
if(CMAKE_CXX_SCAN_FOR_MODULES)
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
endif()
