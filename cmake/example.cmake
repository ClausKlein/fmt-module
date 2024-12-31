include(ExternalProject)

ExternalProject_Add(
  example
  PREFIX ${CMAKE_CURRENT_BINARY_DIR}/example
  #--Download step--------------
  SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR}/example
  #--Update/Patch step----------
  #--Configure step-------------
  USES_TERMINAL_CONFIGURE TRUE
  CONFIGURE_COMMAND cmake -G "${CMAKE_GENERATOR}" -S ${CMAKE_CURRENT_SOURCE_DIR}/example -B . #
                    -D CMAKE_BUILD_TYPE=$<CONFIG> -D CMAKE_CXX_COMPILER=${CMAKE_CXX_COMPILER}
  #--Build step-----------------
  USES_TERMINAL_BUILD TRUE
  # BUILD_IN_SOURCE 1
  BUILD_COMMAND cmake --build <BINARY_DIR> -j 8
  #--Install step---------------
  USES_TERMINAL_INSTALL TRUE
  INSTALL_COMMAND ctest --verbose
  #--Logging -------------------
  LOG_BUILD OFF
)
