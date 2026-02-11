#include "image_compress_core.h"

#include <algorithm>
#include <cmath>
#include <cstdio>
#include <cstdlib>
#include <cstring>

extern "C" {
#include <jpeglib.h>
#include <png.h>
}
#include <webp/decode.h>
#include <webp/encode.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

namespace fic {

ImageFormat DetectImageFormat(const uint8_t* data, size_t size) {
  if (size >= 2 && data[0] == 0xFF && data[1] == 0xD8) {
    return ImageFormat::kJpeg;
  }
  if (size >= 8 && data[0] == 0x89 && data[1] == 0x50 && data[2] == 0x4E &&
      data[3] == 0x47) {
    return ImageFormat::kPng;
  }
  if (size >= 12 && data[0] == 'R' && data[1] == 'I' && data[2] == 'F' &&
      data[3] == 'F' && data[8] == 'W' && data[9] == 'E' && data[10] == 'B' &&
      data[11] == 'P') {
    return ImageFormat::kWebp;
  }
  if (size >= 12 && data[4] == 'f' && data[5] == 't' && data[6] == 'y' &&
      data[7] == 'p') {
    // This could be HEIC/HEIF; we treat as HEIC to report unsupported.
    return ImageFormat::kHeic;
  }
  return ImageFormat::kUnknown;
}

bool ReadFileToBytes(const std::string& path, std::vector<uint8_t>* out,
                     std::string* error) {
  FILE* file = std::fopen(path.c_str(), "rb");
  if (!file) {
    if (error) *error = "Failed to open file: " + path;
    return false;
  }
  std::fseek(file, 0, SEEK_END);
  long size = std::ftell(file);
  std::fseek(file, 0, SEEK_SET);
  if (size <= 0) {
    std::fclose(file);
    if (error) *error = "Empty file: " + path;
    return false;
  }
  out->resize(static_cast<size_t>(size));
  size_t read = std::fread(out->data(), 1, out->size(), file);
  std::fclose(file);
  if (read != out->size()) {
    if (error) *error = "Failed to read file: " + path;
    return false;
  }
  return true;
}

bool WriteBytesToFile(const std::string& path, const std::vector<uint8_t>& data,
                      std::string* error) {
  FILE* file = std::fopen(path.c_str(), "wb");
  if (!file) {
    if (error) *error = "Failed to write file: " + path;
    return false;
  }
  size_t written = std::fwrite(data.data(), 1, data.size(), file);
  std::fclose(file);
  if (written != data.size()) {
    if (error) *error = "Failed to write file: " + path;
    return false;
  }
  return true;
}

struct JpegErrorManager {
  jpeg_error_mgr pub;
  jmp_buf setjmp_buffer;
};

static void JpegErrorExit(j_common_ptr cinfo) {
  JpegErrorManager* err = reinterpret_cast<JpegErrorManager*>(cinfo->err);
  longjmp(err->setjmp_buffer, 1);
}

static bool DecodeJpeg(const std::vector<uint8_t>& input, ImageBuffer* out,
                       std::string* error) {
  jpeg_decompress_struct cinfo;
  JpegErrorManager jerr;
  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = JpegErrorExit;
  if (setjmp(jerr.setjmp_buffer)) {
    jpeg_destroy_decompress(&cinfo);
    if (error) *error = "JPEG decode failed";
    return false;
  }
  jpeg_create_decompress(&cinfo);
  jpeg_mem_src(&cinfo, input.data(), input.size());
  jpeg_read_header(&cinfo, TRUE);
  jpeg_start_decompress(&cinfo);

  int width = cinfo.output_width;
  int height = cinfo.output_height;
  int components = cinfo.output_components;
  if (components != 3 && components != 1) {
    jpeg_finish_decompress(&cinfo);
    jpeg_destroy_decompress(&cinfo);
    if (error) *error = "Unsupported JPEG components";
    return false;
  }
  out->width = width;
  out->height = height;
  out->channels = 4;
  out->data.resize(static_cast<size_t>(width * height * 4));

  std::vector<uint8_t> row_buf(width * components);
  while (cinfo.output_scanline < cinfo.output_height) {
    JSAMPROW row_pointer = row_buf.data();
    jpeg_read_scanlines(&cinfo, &row_pointer, 1);
    int y = cinfo.output_scanline - 1;
    for (int x = 0; x < width; ++x) {
      uint8_t r, g, b;
      if (components == 1) {
        r = g = b = row_buf[x];
      } else {
        r = row_buf[x * 3 + 0];
        g = row_buf[x * 3 + 1];
        b = row_buf[x * 3 + 2];
      }
      size_t idx = static_cast<size_t>((y * width + x) * 4);
      out->data[idx + 0] = r;
      out->data[idx + 1] = g;
      out->data[idx + 2] = b;
      out->data[idx + 3] = 255;
    }
  }

  jpeg_finish_decompress(&cinfo);
  jpeg_destroy_decompress(&cinfo);
  return true;
}

static bool DecodePng(const std::vector<uint8_t>& input, ImageBuffer* out,
                      std::string* error) {
  png_image image;
  std::memset(&image, 0, sizeof(image));
  image.version = PNG_IMAGE_VERSION;

  if (!png_image_begin_read_from_memory(&image, input.data(), input.size())) {
    if (error) *error = "PNG read header failed";
    return false;
  }

  image.format = PNG_FORMAT_RGBA;
  out->width = image.width;
  out->height = image.height;
  out->channels = 4;
  out->data.resize(PNG_IMAGE_SIZE(image));

  if (!png_image_finish_read(&image, nullptr, out->data.data(), 0, nullptr)) {
    if (error) *error = "PNG decode failed";
    png_image_free(&image);
    return false;
  }
  png_image_free(&image);
  return true;
}

static bool DecodeWebp(const std::vector<uint8_t>& input, ImageBuffer* out,
                       std::string* error) {
  int width = 0;
  int height = 0;
  if (!WebPGetInfo(input.data(), input.size(), &width, &height)) {
    if (error) *error = "WebP header parse failed";
    return false;
  }
  uint8_t* rgba = WebPDecodeRGBA(input.data(), input.size(), &width, &height);
  if (!rgba) {
    if (error) *error = "WebP decode failed";
    return false;
  }
  out->width = width;
  out->height = height;
  out->channels = 4;
  out->data.assign(rgba, rgba + (width * height * 4));
  WebPFree(rgba);
  return true;
}

bool DecodeImage(const std::vector<uint8_t>& input, ImageBuffer* out,
                 ImageFormat* detected, std::string* error) {
  if (input.empty()) {
    if (error) *error = "Empty input";
    return false;
  }
  ImageFormat fmt = DetectImageFormat(input.data(), input.size());
  if (detected) *detected = fmt;
  switch (fmt) {
    case ImageFormat::kJpeg:
      return DecodeJpeg(input, out, error);
    case ImageFormat::kPng:
      return DecodePng(input, out, error);
    case ImageFormat::kWebp:
      return DecodeWebp(input, out, error);
    case ImageFormat::kHeic:
      if (error) *error = "HEIC not supported";
      return false;
    default:
      if (error) *error = "Unknown image format";
      return false;
  }
}

static bool EncodeJpeg(const ImageBuffer& image, int quality,
                       std::vector<uint8_t>* out, std::string* error) {
  jpeg_compress_struct cinfo;
  JpegErrorManager jerr;
  cinfo.err = jpeg_std_error(&jerr.pub);
  jerr.pub.error_exit = JpegErrorExit;
  if (setjmp(jerr.setjmp_buffer)) {
    jpeg_destroy_compress(&cinfo);
    if (error) *error = "JPEG encode failed";
    return false;
  }

  jpeg_create_compress(&cinfo);
  unsigned char* mem = nullptr;
  unsigned long mem_size = 0;
  jpeg_mem_dest(&cinfo, &mem, &mem_size);

  cinfo.image_width = image.width;
  cinfo.image_height = image.height;
  cinfo.input_components = 3;
  cinfo.in_color_space = JCS_RGB;
  jpeg_set_defaults(&cinfo);
  jpeg_set_quality(&cinfo, std::max(1, std::min(quality, 100)), TRUE);

  jpeg_start_compress(&cinfo, TRUE);

  std::vector<uint8_t> row(image.width * 3);
  while (cinfo.next_scanline < cinfo.image_height) {
    int y = cinfo.next_scanline;
    for (int x = 0; x < image.width; ++x) {
      size_t idx = static_cast<size_t>((y * image.width + x) * 4);
      row[x * 3 + 0] = image.data[idx + 0];
      row[x * 3 + 1] = image.data[idx + 1];
      row[x * 3 + 2] = image.data[idx + 2];
    }
    JSAMPROW row_pointer = row.data();
    jpeg_write_scanlines(&cinfo, &row_pointer, 1);
  }

  jpeg_finish_compress(&cinfo);
  out->assign(mem, mem + mem_size);
  jpeg_destroy_compress(&cinfo);
  free(mem);
  return true;
}

static bool EncodePng(const ImageBuffer& image, std::vector<uint8_t>* out,
                      std::string* error) {
  png_image img;
  std::memset(&img, 0, sizeof(img));
  img.version = PNG_IMAGE_VERSION;
  img.width = image.width;
  img.height = image.height;
  img.format = PNG_FORMAT_RGBA;

  size_t size = 0;
  if (!png_image_write_to_memory(&img, nullptr, &size, 0, image.data.data(), 0,
                                 nullptr)) {
    if (error) *error = "PNG encode failed";
    return false;
  }
  out->resize(size);
  if (!png_image_write_to_memory(&img, out->data(), &size, 0, image.data.data(),
                                 0, nullptr)) {
    if (error) *error = "PNG encode failed";
    return false;
  }
  out->resize(size);
  return true;
}

static bool EncodeWebp(const ImageBuffer& image, int quality,
                       std::vector<uint8_t>* out, std::string* error) {
  uint8_t* data = nullptr;
  size_t size = WebPEncodeRGBA(image.data.data(), image.width, image.height,
                               image.width * 4, quality, &data);
  if (size == 0 || !data) {
    if (error) *error = "WebP encode failed";
    return false;
  }
  out->assign(data, data + size);
  WebPFree(data);
  return true;
}

bool EncodeImage(const ImageBuffer& image, ImageFormat format, int quality,
                 std::vector<uint8_t>* out, std::string* error) {
  switch (format) {
    case ImageFormat::kJpeg:
      return EncodeJpeg(image, quality, out, error);
    case ImageFormat::kPng:
      return EncodePng(image, out, error);
    case ImageFormat::kWebp:
      return EncodeWebp(image, quality, out, error);
    case ImageFormat::kHeic:
      if (error) *error = "HEIC not supported";
      return false;
    default:
      if (error) *error = "Unsupported output format";
      return false;
  }
}

static inline uint8_t ClampToByte(float v) {
  if (v < 0.0f) return 0;
  if (v > 255.0f) return 255;
  return static_cast<uint8_t>(v + 0.5f);
}

ImageBuffer ResizeImageBilinear(const ImageBuffer& src, int target_w,
                                int target_h) {
  ImageBuffer out;
  out.width = std::max(1, target_w);
  out.height = std::max(1, target_h);
  out.channels = 4;
  out.data.resize(static_cast<size_t>(out.width * out.height * 4));

  const float x_scale = static_cast<float>(src.width) / out.width;
  const float y_scale = static_cast<float>(src.height) / out.height;

  for (int y = 0; y < out.height; ++y) {
    float sy = (y + 0.5f) * y_scale - 0.5f;
    int y0 = static_cast<int>(floorf(sy));
    int y1 = std::min(y0 + 1, src.height - 1);
    float fy = sy - y0;
    y0 = std::max(0, y0);

    for (int x = 0; x < out.width; ++x) {
      float sx = (x + 0.5f) * x_scale - 0.5f;
      int x0 = static_cast<int>(floorf(sx));
      int x1 = std::min(x0 + 1, src.width - 1);
      float fx = sx - x0;
      x0 = std::max(0, x0);

      for (int c = 0; c < 4; ++c) {
        float v00 = src.data[(y0 * src.width + x0) * 4 + c];
        float v10 = src.data[(y0 * src.width + x1) * 4 + c];
        float v01 = src.data[(y1 * src.width + x0) * 4 + c];
        float v11 = src.data[(y1 * src.width + x1) * 4 + c];

        float v0 = v00 + (v10 - v00) * fx;
        float v1 = v01 + (v11 - v01) * fx;
        float v = v0 + (v1 - v0) * fy;
        out.data[(y * out.width + x) * 4 + c] = ClampToByte(v);
      }
    }
  }

  return out;
}

ImageBuffer FlipHorizontal(const ImageBuffer& src) {
  ImageBuffer out = src;
  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width / 2; ++x) {
      int x2 = src.width - 1 - x;
      for (int c = 0; c < 4; ++c) {
        std::swap(out.data[(y * src.width + x) * 4 + c],
                  out.data[(y * src.width + x2) * 4 + c]);
      }
    }
  }
  return out;
}

ImageBuffer FlipVertical(const ImageBuffer& src) {
  ImageBuffer out = src;
  for (int y = 0; y < src.height / 2; ++y) {
    int y2 = src.height - 1 - y;
    for (int x = 0; x < src.width; ++x) {
      for (int c = 0; c < 4; ++c) {
        std::swap(out.data[(y * src.width + x) * 4 + c],
                  out.data[(y2 * src.width + x) * 4 + c]);
      }
    }
  }
  return out;
}

static ImageBuffer RotateImage90(const ImageBuffer& src) {
  ImageBuffer out;
  out.width = src.height;
  out.height = src.width;
  out.channels = 4;
  out.data.resize(static_cast<size_t>(out.width * out.height * 4));

  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x) {
      int nx = src.height - 1 - y;
      int ny = x;
      size_t src_idx = static_cast<size_t>((y * src.width + x) * 4);
      size_t dst_idx = static_cast<size_t>((ny * out.width + nx) * 4);
      std::memcpy(&out.data[dst_idx], &src.data[src_idx], 4);
    }
  }
  return out;
}

static ImageBuffer RotateImage180(const ImageBuffer& src) {
  ImageBuffer out = src;
  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x) {
      int nx = src.width - 1 - x;
      int ny = src.height - 1 - y;
      size_t src_idx = static_cast<size_t>((y * src.width + x) * 4);
      size_t dst_idx = static_cast<size_t>((ny * src.width + nx) * 4);
      std::memcpy(&out.data[dst_idx], &src.data[src_idx], 4);
    }
  }
  return out;
}

static ImageBuffer RotateImage270(const ImageBuffer& src) {
  ImageBuffer out;
  out.width = src.height;
  out.height = src.width;
  out.channels = 4;
  out.data.resize(static_cast<size_t>(out.width * out.height * 4));

  for (int y = 0; y < src.height; ++y) {
    for (int x = 0; x < src.width; ++x) {
      int nx = y;
      int ny = src.width - 1 - x;
      size_t src_idx = static_cast<size_t>((y * src.width + x) * 4);
      size_t dst_idx = static_cast<size_t>((ny * out.width + nx) * 4);
      std::memcpy(&out.data[dst_idx], &src.data[src_idx], 4);
    }
  }
  return out;
}

static void SampleBilinear(const ImageBuffer& src, float x, float y,
                           uint8_t* out_px) {
  int x0 = static_cast<int>(floorf(x));
  int y0 = static_cast<int>(floorf(y));
  int x1 = x0 + 1;
  int y1 = y0 + 1;

  if (x0 < 0 || y0 < 0 || x1 >= src.width || y1 >= src.height) {
    out_px[0] = 0;
    out_px[1] = 0;
    out_px[2] = 0;
    out_px[3] = 0;
    return;
  }

  float fx = x - x0;
  float fy = y - y0;

  for (int c = 0; c < 4; ++c) {
    float v00 = src.data[(y0 * src.width + x0) * 4 + c];
    float v10 = src.data[(y0 * src.width + x1) * 4 + c];
    float v01 = src.data[(y1 * src.width + x0) * 4 + c];
    float v11 = src.data[(y1 * src.width + x1) * 4 + c];

    float v0 = v00 + (v10 - v00) * fx;
    float v1 = v01 + (v11 - v01) * fx;
    float v = v0 + (v1 - v0) * fy;
    out_px[c] = ClampToByte(v);
  }
}

ImageBuffer RotateImage(const ImageBuffer& src, int angle_degrees) {
  int angle = angle_degrees % 360;
  if (angle < 0) angle += 360;
  if (angle == 0) return src;
  if (angle == 90) return RotateImage90(src);
  if (angle == 180) return RotateImage180(src);
  if (angle == 270) return RotateImage270(src);

  const float rad = angle * static_cast<float>(M_PI) / 180.0f;
  const float cosv = std::cos(rad);
  const float sinv = std::sin(rad);

  int new_w = static_cast<int>(std::ceil(std::abs(src.width * cosv) +
                                         std::abs(src.height * sinv)));
  int new_h = static_cast<int>(std::ceil(std::abs(src.width * sinv) +
                                         std::abs(src.height * cosv)));

  ImageBuffer out;
  out.width = std::max(1, new_w);
  out.height = std::max(1, new_h);
  out.channels = 4;
  out.data.assign(static_cast<size_t>(out.width * out.height * 4), 0);

  float cx = (src.width - 1) / 2.0f;
  float cy = (src.height - 1) / 2.0f;
  float ncx = (out.width - 1) / 2.0f;
  float ncy = (out.height - 1) / 2.0f;

  for (int y = 0; y < out.height; ++y) {
    for (int x = 0; x < out.width; ++x) {
      float dx = x - ncx;
      float dy = y - ncy;
      float sx = cosv * dx + sinv * dy + cx;
      float sy = -sinv * dx + cosv * dy + cy;
      uint8_t px[4];
      SampleBilinear(src, sx, sy, px);
      size_t dst_idx = static_cast<size_t>((y * out.width + x) * 4);
      out.data[dst_idx + 0] = px[0];
      out.data[dst_idx + 1] = px[1];
      out.data[dst_idx + 2] = px[2];
      out.data[dst_idx + 3] = px[3];
    }
  }

  return out;
}

void CalcTargetSize(int src_w, int src_h, int min_w, int min_h, int in_sample,
                    int* out_w, int* out_h) {
  double scale_w = static_cast<double>(src_w) / std::max(1, min_w);
  double scale_h = static_cast<double>(src_h) / std::max(1, min_h);
  double scale = std::max(1.0, std::min(scale_w, scale_h));
  if (in_sample > 1) {
    scale = std::max(scale, static_cast<double>(in_sample));
  }
  int target_w = static_cast<int>(std::round(src_w / scale));
  int target_h = static_cast<int>(std::round(src_h / scale));
  *out_w = std::max(1, target_w);
  *out_h = std::max(1, target_h);
}

}  // namespace fic
