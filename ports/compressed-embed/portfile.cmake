file(READ "${CMAKE_CURRENT_LIST_DIR}/version.json" VERSION_JSON)
string(JSON VERSION_REF GET "${VERSION_JSON}" "commit")
string(JSON VERSION_SHA512 GET "${VERSION_JSON}" "sha512")
string(JSON REPO GET "${VERSION_JSON}" "repo")
string(JSON HEAD_REF GET "${VERSION_JSON}" "branch")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO ${REPO}
  REF ${VERSION_REF}
  SHA512 ${VERSION_SHA512}
  HEAD_REF ${HEAD_REF}
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  GENERATOR Ninja
)

vcpkg_cmake_install()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# merge debug and release, and put in share/${PORT}/cmake
vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/compressed-embed")
# vcpkg wants tools in tools/, not bin/
vcpkg_copy_tools(TOOL_NAMES compressed-embed AUTO_CLEAN)
# Shared between debug and release builds
file(
  REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/share"
  "${CURRENT_PACKAGES_DIR}/debug/include"
)
