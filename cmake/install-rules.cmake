include(cmake/AddUninstallTarget.cmake)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# Print Installing but not Up-to-date messages.
set(CMAKE_INSTALL_MESSAGE LAZY)

# find_package(<package) call for consumers to find this project
set(_package fmt)

# Allow package maintainers to freely override the path for the configs
set(FMT_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${_package}"
    CACHE PATH "CMake package config location relative to the install prefix"
)
mark_as_advanced(FMT_INSTALL_CMAKEDIR)

install(TARGETS fmt-header-only EXPORT fmtTargets FILE_SET HEADERS)

if(FMT_USE_MODULES)
  install(TARGETS fmt EXPORT fmtTargets FILE_SET public_headers #
                                        FILE_SET public_modules DESTINATION ${FMT_INSTALL_CMAKEDIR}/module
  )
else()
  install(TARGETS fmt EXPORT fmtTargets FILE_SET public_headers)
endif()
install(FILES module/fmt.cppm DESTINATION ${FMT_INSTALL_CMAKEDIR}/module)
install(FILES ${_fmt_all_sources} DESTINATION ${FMT_INSTALL_CMAKEDIR}/module)

write_basic_package_version_file("${_package}ConfigVersion.cmake" COMPATIBILITY SameMajorVersion ARCH_INDEPENDENT)

configure_file(cmake/install-config.cmake install-config.cmake @ONLY)
install(FILES ${PROJECT_BINARY_DIR}/install-config.cmake DESTINATION "${FMT_INSTALL_CMAKEDIR}"
        RENAME "${_package}Config.cmake" COMPONENT fmt_Development
)

install(FILES "${PROJECT_BINARY_DIR}/${_package}ConfigVersion.cmake" DESTINATION "${FMT_INSTALL_CMAKEDIR}"
        COMPONENT fmt_Development
)

if(FMT_USE_MODULES)
  install(EXPORT fmtTargets
          NAMESPACE fmt::
          DESTINATION "${FMT_INSTALL_CMAKEDIR}"
          COMPONENT fmt_Development
          CXX_MODULES_DIRECTORY .
  )
else()
  install(EXPORT fmtTargets NAMESPACE fmt:: DESTINATION "${FMT_INSTALL_CMAKEDIR}" COMPONENT fmt_Development)
endif()

if(PROJECT_IS_TOP_LEVEL)
  set(CPACK_GENERATOR TGZ)
  include(CPack)
endif()
