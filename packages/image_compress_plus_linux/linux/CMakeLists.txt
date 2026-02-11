cmake_minimum_required(VERSION 3.10)
set(PROJECT_NAME "image_compress_plus_linux")
project(${PROJECT_NAME} LANGUAGES C CXX)

set(PLUGIN_NAME "image_compress_plus_linux_plugin")

add_library(${PLUGIN_NAME} SHARED
  "image_compress_plus_linux_plugin.cc"
  "../desktop/image_compress_core.cc"
  "../desktop/exif_utils.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
)

target_include_directories(${PLUGIN_NAME} PRIVATE
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../desktop"
)

find_package(PkgConfig REQUIRED)

pkg_check_modules(LIBJPEG REQUIRED libjpeg)
pkg_check_modules(LIBPNG REQUIRED libpng)
pkg_check_modules(LIBWEBP REQUIRED libwebp)
pkg_check_modules(EXIV2 REQUIRED exiv2)

find_package(Flutter REQUIRED)

# GTK is required by the Flutter Linux shell.
pkg_check_modules(GTK REQUIRED gtk+-3.0)

include_directories(
  ${LIBJPEG_INCLUDE_DIRS}
  ${LIBPNG_INCLUDE_DIRS}
  ${LIBWEBP_INCLUDE_DIRS}
  ${EXIV2_INCLUDE_DIRS}
  ${GTK_INCLUDE_DIRS}
)

link_directories(
  ${LIBJPEG_LIBRARY_DIRS}
  ${LIBPNG_LIBRARY_DIRS}
  ${LIBWEBP_LIBRARY_DIRS}
  ${EXIV2_LIBRARY_DIRS}
  ${GTK_LIBRARY_DIRS}
)

target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  ${GTK_LIBRARIES}
  ${LIBJPEG_LIBRARIES}
  ${LIBPNG_LIBRARIES}
  ${LIBWEBP_LIBRARIES}
  ${EXIV2_LIBRARIES}
)

set(image_compress_plus_linux_bundled_libraries
  ""
  PARENT_SCOPE
)
