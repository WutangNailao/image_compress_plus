#ifndef IMAGE_COMPRESS_PLUS_WINDOWS_PLUGIN_H_
#define IMAGE_COMPRESS_PLUS_WINDOWS_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>

#include <memory>

namespace image_compress_plus_windows {

class ImageCompressPlusWindowsPlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows* registrar);

  ImageCompressPlusWindowsPlugin();
  virtual ~ImageCompressPlusWindowsPlugin();

  // Disallow copy and assign.
  ImageCompressPlusWindowsPlugin(const ImageCompressPlusWindowsPlugin&) = delete;
  ImageCompressPlusWindowsPlugin& operator=(const ImageCompressPlusWindowsPlugin&) = delete;

 private:
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue>& method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
};

}  // namespace image_compress_plus_windows

#ifdef __cplusplus
extern "C" {
#endif

void ImageCompressPlusWindowsPluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#ifdef __cplusplus
}  // extern "C"
#endif

#endif  // IMAGE_COMPRESS_PLUS_WINDOWS_PLUGIN_H_
