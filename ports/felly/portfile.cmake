file(READ "${CMAKE_CURRENT_LIST_DIR}/version.json" VERSION_JSON)
string(JSON VERSION_REF GET "${VERSION_JSON}" "commit")
string(JSON VERSION_SHA512 GET "${VERSION_JSON}" "sha512")
string(JSON VERSION_BRANCH GET "${VERSION_JSON}" "branch")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO fredemmott/felly
  REF "${VERSION_REF}"
  SHA512 "${VERSION_SHA512}"
  HEAD_REF "${VERSION_BRANCH}"
)

file(
  INSTALL "${SOURCE_PATH}/include/"
  DESTINATION "${CURRENT_PACKAGES_DIR}/include"
  FILES_MATCHING
  PATTERN "*.h"
  PATTERN "*.hpp"
)

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

include(CMakePackageConfigHelpers)
macro(make_package_config_file PREFIX)
  configure_package_config_file(
    "${CMAKE_CURRENT_LIST_DIR}/felly-config.cmake.in"
    "${CURRENT_PACKAGES_DIR}/${PREFIX}/${PORT}/${PORT}-config.cmake"
    INSTALL_DESTINATION "${PREFIX}/${PORT}"
  )
endmacro()
make_package_config_file("share")
make_package_config_file("debug/share")
vcpkg_cmake_config_fixup(PACKAGE_NAME "${PORT}")
