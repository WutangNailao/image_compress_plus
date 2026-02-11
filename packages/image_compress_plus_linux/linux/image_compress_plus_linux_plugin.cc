#include "include/image_compress_plus_linux/image_compress_plus_linux_plugin.h"

#include <flutter_linux/flutter_linux.h>
#include <gtk/gtk.h>

#include <cmath>
#include <cstring>
#include <memory>
#include <string>
#include <utility>
#include <vector>

#include "../desktop/image_compress_core.h"
#include "../desktop/exif_utils.h"

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

static bool GetInt(FlValue* value, int* out) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_INT) {
    return false;
  }
  *out = static_cast<int>(fl_value_get_int(value));
  return true;
}

static bool GetBool(FlValue* value, bool* out) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_BOOL) {
    return false;
  }
  *out = fl_value_get_bool(value);
  return true;
}

static bool GetString(FlValue* value, std::string* out) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_STRING) {
    return false;
  }
  *out = fl_value_get_string(value);
  return true;
}

static bool GetUint8List(FlValue* value, std::vector<uint8_t>* out) {
  if (fl_value_get_type(value) != FL_VALUE_TYPE_UINT8_LIST) {
    return false;
  }
  size_t length = 0;
  const uint8_t* data = fl_value_get_uint8_list(value, &length);
  if (!data || length == 0) {
    return false;
  }
  out->assign(data, data + length);
  return true;
}

static std::string MakeTempPath(const std::string& ext) {
  gchar* uuid = g_uuid_string_random();
  gchar* filename = g_strdup_printf("fic_%s.%s", uuid, ext.c_str());
  gchar* path = g_build_filename(g_get_tmp_dir(), filename, nullptr);
  std::string out(path);
  g_free(uuid);
  g_free(filename);
  g_free(path);
  return out;
}

static fic::ImageBuffer ApplyOrientation(const fic::ImageBuffer& src,
                                         int orientation) {
  switch (orientation) {
    case 2: {
      return fic::FlipHorizontal(src);
    }
    case 3: {
      return fic::RotateImage(src, 180);
    }
    case 4: {
      return fic::FlipVertical(src);
    }
    case 5: {
      fic::ImageBuffer flipped = fic::FlipHorizontal(src);
      return fic::RotateImage(flipped, 90);
    }
    case 6: {
      return fic::RotateImage(src, 90);
    }
    case 7: {
      fic::ImageBuffer flipped = fic::FlipHorizontal(src);
      return fic::RotateImage(flipped, 270);
    }
    case 8: {
      return fic::RotateImage(src, 270);
    }
    default:
      return src;
  }
}

static bool ParseListArgs(FlValue* args, std::vector<uint8_t>* input,
                          CompressParams* params, std::string* error) {
  if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_LIST) {
    if (error) *error = "Invalid arguments";
    return false;
  }
  if (fl_value_get_length(args) < 8) {
    if (error) *error = "Arguments length mismatch";
    return false;
  }
  if (!GetUint8List(fl_value_get_list_value(args, 0), input)) {
    if (error) *error = "Missing image bytes";
    return false;
  }
  GetInt(fl_value_get_list_value(args, 1), &params->min_width);
  GetInt(fl_value_get_list_value(args, 2), &params->min_height);
  GetInt(fl_value_get_list_value(args, 3), &params->quality);
  GetInt(fl_value_get_list_value(args, 4), &params->rotate);
  GetBool(fl_value_get_list_value(args, 5), &params->auto_correction);
  GetInt(fl_value_get_list_value(args, 6), &params->format);
  GetBool(fl_value_get_list_value(args, 7), &params->keep_exif);
  if (fl_value_get_length(args) > 8) {
    GetInt(fl_value_get_list_value(args, 8), &params->in_sample);
  }
  return true;
}

static bool ParseFileArgs(FlValue* args, std::string* path,
                          CompressParams* params, std::string* error,
                          bool has_target_path) {
  if (!args || fl_value_get_type(args) != FL_VALUE_TYPE_LIST) {
    if (error) *error = "Invalid arguments";
    return false;
  }
  if (fl_value_get_length(args) < 8) {
    if (error) *error = "Arguments length mismatch";
    return false;
  }
  if (!GetString(fl_value_get_list_value(args, 0), path)) {
    if (error) *error = "Missing source path";
    return false;
  }
  GetInt(fl_value_get_list_value(args, 1), &params->min_width);
  GetInt(fl_value_get_list_value(args, 2), &params->min_height);
  GetInt(fl_value_get_list_value(args, 3), &params->quality);

  if (has_target_path) {
    GetString(fl_value_get_list_value(args, 4), &params->target_path);
    GetInt(fl_value_get_list_value(args, 5), &params->rotate);
    GetBool(fl_value_get_list_value(args, 6), &params->auto_correction);
    GetInt(fl_value_get_list_value(args, 7), &params->format);
    GetBool(fl_value_get_list_value(args, 8), &params->keep_exif);
    if (fl_value_get_length(args) > 9) {
      GetInt(fl_value_get_list_value(args, 9), &params->in_sample);
    }
  } else {
    GetInt(fl_value_get_list_value(args, 4), &params->rotate);
    GetBool(fl_value_get_list_value(args, 5), &params->auto_correction);
    GetInt(fl_value_get_list_value(args, 6), &params->format);
    GetBool(fl_value_get_list_value(args, 7), &params->keep_exif);
    if (fl_value_get_length(args) > 8) {
      GetInt(fl_value_get_list_value(args, 8), &params->in_sample);
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
  if (!fic::DecodeImage(input, &image, &detected, error)) {
    return false;
  }

  if (params.auto_correction && has_exif) {
    int orientation = fic::OrientationFromExif(exif);
    image = ApplyOrientation(image, orientation);
  }

  if (params.rotate != 0) {
    image = fic::RotateImage(image, params.rotate);
  }

  int target_w = image.width;
  int target_h = image.height;
  fic::CalcTargetSize(image.width, image.height, params.min_width,
                      params.min_height, params.in_sample, &target_w,
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
    if (!fic::WriteBytesToFile(temp_path, *output, error)) {
      return false;
    }
    if (!fic::ApplyExifToFile(temp_path, exif, error)) {
      g_remove(temp_path.c_str());
      return true;
    }
    std::vector<uint8_t> final_bytes;
    if (!fic::ReadFileToBytes(temp_path, &final_bytes, error)) {
      return false;
    }
    g_remove(temp_path.c_str());
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
  if (params.keep_exif) {
    fic::ExifPack exif;
    bool has_exif = false;
    if (!src_path.empty()) {
      has_exif = fic::ReadExifFromFile(src_path, &exif, error);
    } else {
      has_exif = fic::ReadExifFromBytes(input, &exif, error);
    }
    if (has_exif && !exif.empty()) {
      if (params.auto_correction || params.rotate != 0) {
        fic::NormalizeOrientation(&exif);
      }
      fic::ApplyExifToFile(params.target_path, exif, error);
    }
  }
  return true;
}

static FlMethodResponse* HandleCompressWithList(FlValue* args) {
  std::vector<uint8_t> input;
  CompressParams params;
  std::string error;
  if (!ParseListArgs(args, &input, &params, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad_args", error.c_str(), nullptr));
  }
  std::vector<uint8_t> output;
  if (!CompressBytes(input, std::string(), params, &output, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "compress_error", error.c_str(), nullptr));
  }
  FlValue* result =
      fl_value_new_uint8_list(output.data(), output.size());
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* HandleCompressWithFile(FlValue* args) {
  std::string path;
  CompressParams params;
  std::string error;
  if (!ParseFileArgs(args, &path, &params, &error, false)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad_args", error.c_str(), nullptr));
  }
  std::vector<uint8_t> input;
  if (!fic::ReadFileToBytes(path, &input, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "read_error", error.c_str(), nullptr));
  }
  std::vector<uint8_t> output;
  if (!CompressBytes(input, path, params, &output, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "compress_error", error.c_str(), nullptr));
  }
  FlValue* result =
      fl_value_new_uint8_list(output.data(), output.size());
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

static FlMethodResponse* HandleCompressAndGetFile(FlValue* args) {
  std::string path;
  CompressParams params;
  std::string error;
  if (!ParseFileArgs(args, &path, &params, &error, true)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "bad_args", error.c_str(), nullptr));
  }
  std::vector<uint8_t> input;
  if (!fic::ReadFileToBytes(path, &input, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "read_error", error.c_str(), nullptr));
  }
  if (!CompressToFile(input, path, params, &error)) {
    return FL_METHOD_RESPONSE(fl_method_error_response_new(
        "compress_error", error.c_str(), nullptr));
  }
  FlValue* result = fl_value_new_string(params.target_path.c_str());
  return FL_METHOD_RESPONSE(fl_method_success_response_new(result));
}

}  // namespace

struct _ImageCompressPlusLinuxPlugin {
  GObject parent_instance;
};

G_DEFINE_TYPE(ImageCompressPlusLinuxPlugin,
              image_compress_plus_linux_plugin,
              g_object_get_type())

static void image_compress_plus_linux_plugin_handle_method_call(
    ImageCompressPlusLinuxPlugin* self, FlMethodCall* method_call) {
  const gchar* method = fl_method_call_get_name(method_call);
  FlValue* args = fl_method_call_get_args(method_call);

  FlMethodResponse* response = nullptr;
  if (strcmp(method, "compressWithList") == 0) {
    response = HandleCompressWithList(args);
  } else if (strcmp(method, "compressWithFile") == 0) {
    response = HandleCompressWithFile(args);
  } else if (strcmp(method, "compressWithFileAndGetFile") == 0 ||
             strcmp(method, "compressAndGetFile") == 0) {
    response = HandleCompressAndGetFile(args);
  } else if (strcmp(method, "showLog") == 0) {
    response = FL_METHOD_RESPONSE(fl_method_success_response_new(nullptr));
  } else if (strcmp(method, "getSystemVersion") == 0) {
    response = FL_METHOD_RESPONSE(
        fl_method_success_response_new(fl_value_new_string("0")));
  } else {
    response = FL_METHOD_RESPONSE(fl_method_not_implemented_response_new());
  }

  fl_method_call_respond(method_call, response, nullptr);
}

static void image_compress_plus_linux_plugin_dispose(GObject* object) {
  G_OBJECT_CLASS(image_compress_plus_linux_plugin_parent_class)
      ->dispose(object);
}

static void image_compress_plus_linux_plugin_class_init(
    ImageCompressPlusLinuxPluginClass* klass) {
  G_OBJECT_CLASS(klass)->dispose =
      image_compress_plus_linux_plugin_dispose;
}

static void image_compress_plus_linux_plugin_init(
    ImageCompressPlusLinuxPlugin* self) {}

void image_compress_plus_linux_plugin_register_with_registrar(
    FlPluginRegistrar* registrar) {
  ImageCompressPlusLinuxPlugin* plugin =
      IMAGE_COMPRESS_PLUS_LINUX_PLUGIN(
          g_object_new(image_compress_plus_linux_plugin_get_type(),
                       nullptr));

  g_autoptr(FlStandardMethodCodec) codec = fl_standard_method_codec_new();
  g_autoptr(FlMethodChannel) channel = fl_method_channel_new(
      fl_plugin_registrar_get_messenger(registrar), kChannelName,
      FL_METHOD_CODEC(codec));

  fl_method_channel_set_method_call_handler(
      channel,
      [](FlMethodChannel*, FlMethodCall* method_call, gpointer user_data) {
        auto* plugin =
            IMAGE_COMPRESS_PLUS_LINUX_PLUGIN(user_data);
        image_compress_plus_linux_plugin_handle_method_call(plugin,
                                                                method_call);
      },
      g_object_ref(plugin), g_object_unref);
}
