#ifndef FLUTTER_IMAGE_COMPRESS_COMMON_DESKTOP_IMAGE_COMPRESS_CORE_H_
#define FLUTTER_IMAGE_COMPRESS_COMMON_DESKTOP_IMAGE_COMPRESS_CORE_H_

#include <cstdint>
#include <string>
#include <vector>

namespace fic {

enum class ImageFormat {
  kJpeg = 0,
  kPng = 1,
  kHeic = 2,
  kWebp = 3,
  kUnknown = 99,
};

struct ImageBuffer {
  int width = 0;
  int height = 0;
  int channels = 4;
  std::vector<uint8_t> data;
};

ImageFormat DetectImageFormat(const uint8_t* data, size_t size);

bool ReadFileToBytes(const std::string& path, std::vector<uint8_t>* out,
                     std::string* error);
bool WriteBytesToFile(const std::string& path, const std::vector<uint8_t>& data,
                      std::string* error);

bool DecodeImage(const std::vector<uint8_t>& input, ImageBuffer* out,
                 ImageFormat* detected, int in_sample, std::string* error);

bool EncodeImage(const ImageBuffer& image, ImageFormat format, int quality,
                 std::vector<uint8_t>* out, std::string* error);

ImageBuffer ResizeImageBilinear(const ImageBuffer& src, int target_w,
                                int target_h);
ImageBuffer RotateImage(const ImageBuffer& src, int angle_degrees);
ImageBuffer FlipHorizontal(const ImageBuffer& src);
ImageBuffer FlipVertical(const ImageBuffer& src);

void CalcTargetSize(int src_w, int src_h, int min_w, int min_h, int in_sample,
                    int* out_w, int* out_h);

}  // namespace fic

#endif  // FLUTTER_IMAGE_COMPRESS_COMMON_DESKTOP_IMAGE_COMPRESS_CORE_H_
