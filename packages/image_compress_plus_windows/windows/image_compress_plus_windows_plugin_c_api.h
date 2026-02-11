#ifndef IMAGE_COMPRESS_PLUS_WINDOWS_PLUGIN_C_API_H_
#define IMAGE_COMPRESS_PLUS_WINDOWS_PLUGIN_C_API_H_

#include <flutter/plugin_registrar_windows.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#ifdef __cplusplus
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void ImageCompressPlusWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // IMAGE_COMPRESS_PLUS_WINDOWS_PLUGIN_C_API_H_
