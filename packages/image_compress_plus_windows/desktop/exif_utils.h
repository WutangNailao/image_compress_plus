#ifndef FLUTTER_IMAGE_COMPRESS_COMMON_DESKTOP_EXIF_UTILS_H_
#define FLUTTER_IMAGE_COMPRESS_COMMON_DESKTOP_EXIF_UTILS_H_

#include <string>
#include <vector>

#include <exiv2/exiv2.hpp>

namespace fic {

struct ExifPack {
  Exiv2::ExifData exif;
  Exiv2::IptcData iptc;
  Exiv2::XmpData xmp;

  bool empty() const {
    return exif.empty() && iptc.empty() && xmp.empty();
  }
};

bool ReadExifFromFile(const std::string& path, ExifPack* out,
                      std::string* error);
bool ReadExifFromBytes(const std::vector<uint8_t>& data, ExifPack* out,
                       std::string* error);
int OrientationFromExif(const ExifPack& exif);
void NormalizeOrientation(ExifPack* exif);
bool ApplyExifToFile(const std::string& path, const ExifPack& exif,
                     std::string* error);

}  // namespace fic

#endif  // FLUTTER_IMAGE_COMPRESS_COMMON_DESKTOP_EXIF_UTILS_H_
