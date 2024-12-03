# if(PROJECT_IS_TOP_LEVEL)
# NO!   set(CMAKE_INSTALL_INCLUDEDIR "include/fmt-${PROJECT_VERSION}" CACHE PATH "")
# endif()

# Project is configured with no languages, so tell GNUInstallDirs the lib dir
set(CMAKE_INSTALL_LIBDIR lib CACHE PATH "")

include(cmake/AddUninstallTarget.cmake)

include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

# Print Installing but not Up-to-date messages.
set(CMAKE_INSTALL_MESSAGE LAZY)

# find_package(<package) call for consumers to find this project
set(_package fmt)

#NO! install(DIRECTORY include/ DESTINATION "${CMAKE_INSTALL_INCLUDEDIR}" COMPONENT fmt_Development)

if(TARGET fmt_header)
  install(TARGETS fmt_header EXPORT fmtTargets FILE_SET HEADERS)
endif()
if(TARGET fmt)
  install(TARGETS fmt EXPORT fmtTargets FILE_SET public_headers)
endif()

write_basic_package_version_file("${_package}ConfigVersion.cmake" COMPATIBILITY SameMajorVersion ARCH_INDEPENDENT)

# Allow package maintainers to freely override the path for the configs
set(FMT_INSTALL_CMAKEDIR "${CMAKE_INSTALL_LIBDIR}/cmake/${_package}"
    CACHE PATH "CMake package config location relative to the install prefix"
)
mark_as_advanced(FMT_INSTALL_CMAKEDIR)

configure_file(cmake/install-config.cmake install-config.cmake @ONLY)
install(FILES ${PROJECT_BINARY_DIR}/install-config.cmake DESTINATION "${FMT_INSTALL_CMAKEDIR}"
        RENAME "${_package}Config.cmake" COMPONENT fmt_Development
)

install(FILES "${PROJECT_BINARY_DIR}/${_package}ConfigVersion.cmake" DESTINATION "${FMT_INSTALL_CMAKEDIR}"
        COMPONENT fmt_Development
)

install(EXPORT fmtTargets NAMESPACE fmt:: DESTINATION "${FMT_INSTALL_CMAKEDIR}" COMPONENT fmt_Development)

if(PROJECT_IS_TOP_LEVEL)
  set(CPACK_GENERATOR TGZ)
  include(CPack)
endif()
