#include "exif_utils.h"

#include <cstdint>

namespace fic {

bool ReadExifFromFile(const std::string& path, ExifPack* out,
                      std::string* error) {
  try {
    auto image = Exiv2::ImageFactory::open(path);
    if (!image.get()) {
      if (error) *error = "Failed to open image for EXIF";
      return false;
    }
    image->readMetadata();
    out->exif = image->exifData();
    out->iptc = image->iptcData();
    out->xmp = image->xmpData();
    return true;
  } catch (const Exiv2::Error& e) {
    if (error) *error = e.what();
    return false;
  }
}

bool ReadExifFromBytes(const std::vector<uint8_t>& data, ExifPack* out,
                       std::string* error) {
  try {
    Exiv2::MemIo mem(data.data(), data.size());
    auto image = Exiv2::ImageFactory::open(&mem);
    if (!image.get()) {
      if (error) *error = "Failed to open memory image for EXIF";
      return false;
    }
    image->readMetadata();
    out->exif = image->exifData();
    out->iptc = image->iptcData();
    out->xmp = image->xmpData();
    return true;
  } catch (const Exiv2::Error& e) {
    if (error) *error = e.what();
    return false;
  }
}

int OrientationFromExif(const ExifPack& exif) {
  try {
    Exiv2::ExifKey key("Exif.Image.Orientation");
    auto it = exif.exif.findKey(key);
    if (it != exif.exif.end()) {
      return static_cast<int>(it->toLong());
    }
  } catch (const Exiv2::Error&) {
  }
  return 1;
}

void NormalizeOrientation(ExifPack* exif) {
  try {
    Exiv2::ExifKey key("Exif.Image.Orientation");
    Exiv2::ExifData& data = exif->exif;
    Exiv2::Value::UniquePtr v = Exiv2::Value::create(Exiv2::unsignedShort);
    v->read("1");
    data[key] = *v;
  } catch (const Exiv2::Error&) {
  }
}

bool ApplyExifToFile(const std::string& path, const ExifPack& exif,
                     std::string* error) {
  try {
    auto image = Exiv2::ImageFactory::open(path);
    if (!image.get()) {
      if (error) *error = "Failed to open output image for EXIF";
      return false;
    }
    image->readMetadata();
    image->setExifData(exif.exif);
    image->setIptcData(exif.iptc);
    image->setXmpData(exif.xmp);
    image->writeMetadata();
    return true;
  } catch (const Exiv2::Error& e) {
    if (error) *error = e.what();
    return false;
  }
}

}  // namespace fic
