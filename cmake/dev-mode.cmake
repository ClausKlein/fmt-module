include(cmake/folders.cmake)

option(FMT_BUILD_TESTING "Use ctest" ON)
if(FMT_BUILD_TESTING)
  enable_testing()

  add_subdirectory(src/tests)
  add_subdirectory(module/tests)
endif()

option(FMT_BUILD_MCSS_DOCS "Build documentation using Doxygen and m.css" OFF)
if(FMT_BUILD_MCSS_DOCS)
  include(cmake/docs.cmake)
endif()

option(FMT_ENABLE_COVERAGE "Enable coverage support separate from CTest's" OFF)
if(FMT_ENABLE_COVERAGE)
  include(cmake/coverage.cmake)
endif()

include(cmake/lint-targets.cmake)
include(cmake/spell-targets.cmake)

add_folders(Project)
