file(READ "${CMAKE_CURRENT_LIST_DIR}/version.json" VERSION_JSON)
string(JSON VERSION_REF GET "${VERSION_JSON}" "commit")
string(JSON VERSION_SHA512 GET "${VERSION_JSON}" "sha512")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO fredemmott/magic_args
  REF ${VERSION_REF}
  SHA512 ${VERSION_SHA512}
  HEAD_REF develop
)

set(VCPKG_BUILD_TYPE release) # header-only

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  GENERATOR Ninja
  OPTIONS
  -DBUILD_TESTING=OFF
  -DBUILD_EXAMPLES=OFF
)

vcpkg_cmake_install()
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

vcpkg_cmake_config_fixup(
  CONFIG_PATH
  "lib/cmake/magic_args"
  PACKAGE_NAME "magic_args")

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/lib")
