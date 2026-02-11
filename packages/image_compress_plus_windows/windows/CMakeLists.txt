cmake_minimum_required(VERSION 3.14)
project(image_compress_plus_windows LANGUAGES CXX)

set(PLUGIN_NAME "image_compress_plus_windows_plugin")

add_library(${PLUGIN_NAME} SHARED
  "image_compress_plus_windows_plugin.cpp"
  "image_compress_plus_windows_plugin_c_api.cpp"
  "../desktop/image_compress_core.cc"
  "../desktop/exif_utils.cc"
)

apply_standard_settings(${PLUGIN_NAME})

set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_STANDARD 17
  CXX_STANDARD_REQUIRED ON
)

target_include_directories(${PLUGIN_NAME} PUBLIC
  "${CMAKE_CURRENT_SOURCE_DIR}/include"
  "${CMAKE_CURRENT_SOURCE_DIR}/../desktop"
)

target_compile_definitions(${PLUGIN_NAME} PRIVATE
  FLUTTER_PLUGIN_IMPL
  _CRT_SECURE_NO_WARNINGS
  NOMINMAX
  WIN32_LEAN_AND_MEAN
)

if(MSVC)
  target_compile_options(${PLUGIN_NAME} PRIVATE
    /WX-
    /wd4324
    /wd4611
    /wd4267
    /wd4244
  )
endif()

find_package(JPEG REQUIRED)
find_package(PNG REQUIRED)
find_package(WebP CONFIG REQUIRED)
find_package(Exiv2 CONFIG REQUIRED)

# Flutter libraries
set(FLUTTER_PLUGIN_NAME "image_compress_plus_windows")

# These are the libraries needed for plugins.
target_link_libraries(${PLUGIN_NAME} PRIVATE
  flutter
  flutter_wrapper_plugin
  JPEG::JPEG
  PNG::PNG
  WebP::webp
  Exiv2::exiv2lib
)

set(image_compress_plus_windows_bundled_libraries
  $<TARGET_RUNTIME_DLLS:${PLUGIN_NAME}>
  PARENT_SCOPE
)
