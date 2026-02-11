#include "image_compress_plus_windows/image_compress_plus_windows_plugin.h"

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>

#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#ifndef NOMINMAX
#define NOMINMAX
#endif
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>

#include "../desktop/image_compress_core.h"
#include "../desktop/exif_utils.h"

namespace image_compress_plus_windows {

namespace {

constexpr char kChannelName[] = "image_compress_plus";

struct CompressParams {
  int min_width = 1920;
  int min_height = 1080;
  int quality = 95;
  int rotate = 0;
  bool auto_correction = true;
  int format = 0;
  bool keep_exif = false;
  int in_sample = 1;
  std::string target_path;
};

static bool GetInt(const flutter::EncodableValue& value, int* out) {
  if (std::holds_alternative<int32_t>(value)) {
    *out = std::get<int32_t>(value);
    return true;
  }
  if (std::holds_alternative<int64_t>(value)) {
    *out = static_cast<int>(std::get<int64_t>(value));
    return true;
  }
  return false;
}

static bool GetBool(const flutter::EncodableValue& value, bool* out) {
  if (std::holds_alternative<bool>(value)) {
    *out = std::get<bool>(value);
    return true;
  }
  return false;
}

static bool GetString(const flutter::EncodableValue& value, std::string* out) {
  if (std::holds_alternative<std::string>(value)) {
    *out = std::get<std::string>(value);
    return true;
  }
  return false;
}

static bool GetUint8List(const flutter::EncodableValue& value,
                         std::vector<uint8_t>* out) {
  if (std::holds_alternative<std::vector<uint8_t>>(value)) {
    *out = std::get<std::vector<uint8_t>>(value);
    return true;
  }
  return false;
}

static std::string MakeTempPath(const std::string& ext) {
  char temp_path[MAX_PATH];
  DWORD len = GetTempPathA(MAX_PATH, temp_path);
  if (len == 0 || len > MAX_PATH) {
    return "";
  }
  char filename[MAX_PATH];
  std::snprintf(filename, sizeof(filename), "fic_%lu.%s",
                static_cast<unsigned long>(GetTickCount()), ext.c_str());
  return std::string(temp_path) + filename;
}

static fic::ImageBuffer ApplyOrientation(const fic::ImageBuffer& src,
                                         int orientation) {
  switch (orientation) {
    case 2:
      return fic::FlipHorizontal(src);
    case 3:
      return fic::RotateImage(src, 180);
    case 4:
      return fic::FlipVertical(src);
    case 5: {
      fic::ImageBuffer flipped = fic::FlipHorizontal(src);
      return fic::RotateImage(flipped, 90);
    }
    case 6:
      return fic::RotateImage(src, 90);
    case 7: {
      fic::ImageBuffer flipped = fic::FlipHorizontal(src);
      return fic::RotateImage(flipped, 270);
    }
    case 8:
      return fic::RotateImage(src, 270);
    default:
      return src;
  }
}

static bool ParseListArgs(const flutter::EncodableList& args,
                          std::vector<uint8_t>* input,
                          CompressParams* params, std::string* error) {
  if (args.size() < 8) {
    if (error) *error = "Arguments length mismatch";
    return false;
  }
  if (!GetUint8List(args[0], input)) {
    if (error) *error = "Missing image bytes";
    return false;
  }
  GetInt(args[1], &params->min_width);
  GetInt(args[2], &params->min_height);
  GetInt(args[3], &params->quality);
  GetInt(args[4], &params->rotate);
  GetBool(args[5], &params->auto_correction);
  GetInt(args[6], &params->format);
  GetBool(args[7], &params->keep_exif);
  if (args.size() > 8) {
    GetInt(args[8], &params->in_sample);
  }
  return true;
}

static bool ParseFileArgs(const flutter::EncodableList& args,
                          std::string* path, CompressParams* params,
                          std::string* error, bool has_target_path) {
  if (args.size() < 8) {
    if (error) *error = "Arguments length mismatch";
    return false;
  }
  if (!GetString(args[0], path)) {
    if (error) *error = "Missing source path";
    return false;
  }
  GetInt(args[1], &params->min_width);
  GetInt(args[2], &params->min_height);
  GetInt(args[3], &params->quality);
  if (has_target_path) {
    GetString(args[4], &params->target_path);
    GetInt(args[5], &params->rotate);
    GetBool(args[6], &params->auto_correction);
    GetInt(args[7], &params->format);
    GetBool(args[8], &params->keep_exif);
    if (args.size() > 9) {
      GetInt(args[9], &params->in_sample);
    }
  } else {
    GetInt(args[4], &params->rotate);
    GetBool(args[5], &params->auto_correction);
    GetInt(args[6], &params->format);
    GetBool(args[7], &params->keep_exif);
    if (args.size() > 8) {
      GetInt(args[8], &params->in_sample);
    }
  }
  return true;
}

static bool CompressBytes(const std::vector<uint8_t>& input,
                          const std::string& src_path,
                          const CompressParams& params,
                          std::vector<uint8_t>* output,
                          std::string* error) {
  fic::ExifPack exif;
  bool has_exif = false;
  if (params.keep_exif || params.auto_correction) {
    if (!src_path.empty()) {
      has_exif = fic::ReadExifFromFile(src_path, &exif, error);
    } else {
      has_exif = fic::ReadExifFromBytes(input, &exif, error);
    }
  }

  fic::ImageBuffer image;
  fic::ImageFormat detected = fic::ImageFormat::kUnknown;
  if (!fic::DecodeImage(input, &image, &detected, params.in_sample, error)) {
    return false;
  }

  if (params.auto_correction && has_exif) {
    int orientation = fic::OrientationFromExif(exif);
    image = ApplyOrientation(image, orientation);
  }

  if (params.rotate != 0) {
    image = fic::RotateImage(image, params.rotate);
  }

  int resize_in_sample = params.in_sample;
  // JPEG is already decoder-downsampled by in_sample; avoid applying it twice.
  if (detected == fic::ImageFormat::kJpeg && resize_in_sample > 1) {
    resize_in_sample = 1;
  }

  int target_w = image.width;
  int target_h = image.height;
  fic::CalcTargetSize(image.width, image.height, params.min_width,
                      params.min_height, resize_in_sample, &target_w,
                      &target_h);
  if (target_w != image.width || target_h != image.height) {
    image = fic::ResizeImageBilinear(image, target_w, target_h);
  }

  fic::ImageFormat out_format =
      static_cast<fic::ImageFormat>(params.format);
  if (!fic::EncodeImage(image, out_format, params.quality, output, error)) {
    return false;
  }

  if (params.keep_exif && has_exif && !exif.empty()) {
    if (params.auto_correction || params.rotate != 0) {
      fic::NormalizeOrientation(&exif);
    }
    std::string ext = "jpg";
    if (out_format == fic::ImageFormat::kPng) {
      ext = "png";
    } else if (out_format == fic::ImageFormat::kWebp) {
      ext = "webp";
    }
    std::string temp_path = MakeTempPath(ext);
    if (temp_path.empty()) {
      if (error) *error = "Failed to create temp path";
      return false;
    }
    if (!fic::WriteBytesToFile(temp_path, *output, error)) {
      return false;
    }
    if (!fic::ApplyExifToFile(temp_path, exif, error)) {
      std::remove(temp_path.c_str());
      return true;
    }
    std::vector<uint8_t> final_bytes;
    if (!fic::ReadFileToBytes(temp_path, &final_bytes, error)) {
      return false;
    }
    std::remove(temp_path.c_str());
    *output = std::move(final_bytes);
  }

  return true;
}

static bool CompressToFile(const std::vector<uint8_t>& input,
                           const std::string& src_path,
                           const CompressParams& params, std::string* error) {
  std::vector<uint8_t> output;
  if (!CompressBytes(input, src_path, params, &output, error)) {
    return false;
  }
  if (!fic::WriteBytesToFile(params.target_path, output, error)) {
    return false;
  }
  return true;
}

}  // namespace

ImageCompressPlusWindowsPlugin::ImageCompressPlusWindowsPlugin() {}

ImageCompressPlusWindowsPlugin::~ImageCompressPlusWindowsPlugin() {}

void ImageCompressPlusWindowsPlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows* registrar) {
  auto channel = std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
      registrar->messenger(), kChannelName,
      &flutter::StandardMethodCodec::GetInstance());

  auto plugin = std::make_unique<ImageCompressPlusWindowsPlugin>();

  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](
          const flutter::MethodCall<flutter::EncodableValue>& call,
          std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });

  registrar->AddPlugin(std::move(plugin));
}

void ImageCompressPlusWindowsPlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue>& method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
  const std::string& method = method_call.method_name();
  const auto* args_ptr = method_call.arguments();

  if (method == "compressWithList") {
    if (!args_ptr || !std::holds_alternative<flutter::EncodableList>(*args_ptr)) {
      result->Error("bad_args", "Invalid arguments");
      return;
    }
    auto args = std::get<flutter::EncodableList>(*args_ptr);
    std::vector<uint8_t> input;
    CompressParams params;
    std::string error;
    if (!ParseListArgs(args, &input, &params, &error)) {
      result->Error("bad_args", error);
      return;
    }
    std::vector<uint8_t> output;
    if (!CompressBytes(input, std::string(), params, &output, &error)) {
      result->Error("compress_error", error);
      return;
    }
    result->Success(flutter::EncodableValue(output));
    return;
  }

  if (method == "compressWithFile") {
    if (!args_ptr || !std::holds_alternative<flutter::EncodableList>(*args_ptr)) {
      result->Error("bad_args", "Invalid arguments");
      return;
    }
    auto args = std::get<flutter::EncodableList>(*args_ptr);
    std::string path;
    CompressParams params;
    std::string error;
    if (!ParseFileArgs(args, &path, &params, &error, false)) {
      result->Error("bad_args", error);
      return;
    }
    std::vector<uint8_t> input;
    if (!fic::ReadFileToBytes(path, &input, &error)) {
      result->Error("read_error", error);
      return;
    }
    std::vector<uint8_t> output;
    if (!CompressBytes(input, path, params, &output, &error)) {
      result->Error("compress_error", error);
      return;
    }
    result->Success(flutter::EncodableValue(output));
    return;
  }

  if (method == "compressWithFileAndGetFile" || method == "compressAndGetFile") {
    if (!args_ptr || !std::holds_alternative<flutter::EncodableList>(*args_ptr)) {
      result->Error("bad_args", "Invalid arguments");
      return;
    }
    auto args = std::get<flutter::EncodableList>(*args_ptr);
    std::string path;
    CompressParams params;
    std::string error;
    if (!ParseFileArgs(args, &path, &params, &error, true)) {
      result->Error("bad_args", error);
      return;
    }
    std::vector<uint8_t> input;
    if (!fic::ReadFileToBytes(path, &input, &error)) {
      result->Error("read_error", error);
      return;
    }
    if (!CompressToFile(input, path, params, &error)) {
      result->Error("compress_error", error);
      return;
    }
    result->Success(flutter::EncodableValue(params.target_path));
    return;
  }

  if (method == "showLog") {
    result->Success();
    return;
  }

  if (method == "getSystemVersion") {
    result->Success(flutter::EncodableValue(std::string("0")));
    return;
  }

  result->NotImplemented();
}

}  // namespace image_compress_plus_windows
