#include "image_compress_plus_windows_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "image_compress_plus_windows/image_compress_plus_windows_plugin.h"

void ImageCompressPlusWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  image_compress_plus_windows::ImageCompressPlusWindowsPlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarWindows::FromRef(registrar));
}
