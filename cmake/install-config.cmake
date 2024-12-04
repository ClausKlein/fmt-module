include(CMakeFindDependencyMacro)

function(add_fmt_module NAME)
  set(FMT_ROOT @CMAKE_INSTALL_PREFIX@)
  message(STATUS "FMT_ROOT is: ${FMT_ROOT}")

  add_library(${NAME})
  target_include_directories(${NAME} PRIVATE ${FMT_ROOT}/include)
  target_compile_features(
    ${NAME} PUBLIC "$<$<COMPILE_FEATURES:cxx_std_23>:cxx_std_23>" "$<$<NOT:$<COMPILE_FEATURES:cxx_std_23>>:cxx_std_20>"
  )
  target_compile_options(${NAME} PUBLIC $<$<AND:$<COMPILE_LANGUAGE:CXX>,$<CXX_COMPILER_ID:MSVC>>:/utf-8>)

  list(APPEND CPPdefinitions "@CPPdefinitions@")
  if(CPPdefinitions)
    target_compile_definitions(${NAME} PUBLIC ${CPPdefinitions})
  endif()

  # cmake-format: off
  target_sources(${NAME} PUBLIC
      FILE_SET modules_public
      TYPE CXX_MODULES
      BASE_DIRS ${FMT_ROOT}
      FILES
          ${FMT_ROOT}/lib/cmake/fmt/module/fmt.cppm
  )
  # cmake-format: on
endfunction()

include("${CMAKE_CURRENT_LIST_DIR}/fmtTargets.cmake")
