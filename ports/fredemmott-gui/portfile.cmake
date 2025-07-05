file(READ "${CMAKE_CURRENT_LIST_DIR}/version.json" VERSION_JSON)
string(JSON VERSION_REF GET "${VERSION_JSON}" "commit")
string(JSON VERSION_SHA512 GET "${VERSION_JSON}" "sha512")

vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  REPO fredemmott/fui
  REF ${VERSION_REF}
  SHA512 ${VERSION_SHA512}
  HEAD_REF main
)

vcpkg_check_features(
  OUT_FEATURE_OPTIONS FEATURE_OPTIONS
  FEATURES
  direct2d ENABLE_DIRECT2D
  skia ENABLE_SKIA
)

vcpkg_cmake_configure(
  SOURCE_PATH "${SOURCE_PATH}"
  GENERATOR Ninja
  OPTIONS
  -DENABLE_IMPLICIT_BACKENDS=OFF
  -DENABLE_DEVELOPER_OPTIONS=OFF
  -DENABLE_DIRECT2D=${ENABLE_DIRECT2D}
  -DENABLE_SKIA=${ENABLE_SKIA}
)

vcpkg_cmake_install()

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE" "${SOURCE_PATH}/third-party/microsoft-ui-xaml/LICENSE")
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

# merge debug and release, and put in share/${PORT}/cmake
vcpkg_cmake_config_fixup(CONFIG_PATH "lib/cmake/fredemmott-gui")
# vcpkg wants tools in tools/, not bin/
vcpkg_copy_tools(TOOL_NAMES xaml-to-fui-statictheme AUTO_CLEAN)
# Shared between debug and release builds
file(
  REMOVE_RECURSE
  "${CURRENT_PACKAGES_DIR}/debug/share"
  "${CURRENT_PACKAGES_DIR}/debug/include"
)
