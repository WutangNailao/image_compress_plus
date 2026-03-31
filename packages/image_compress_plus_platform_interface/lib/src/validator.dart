import 'compress_format.dart';

class ImageCompressPlusValidator {
  ImageCompressPlusValidator();

  bool ignoreCheckExtName = false;

  void checkFileNameAndFormat(String name, CompressFormat format) {
    if (ignoreCheckExtName) return;

    final lowerName = name.toLowerCase();
    final validExts = switch (format) {
      CompressFormat.jpeg => ['.jpg', '.jpeg'],
      CompressFormat.png => ['.png'],
      CompressFormat.heic => ['.heic'],
      CompressFormat.webp => ['.webp'],
    };

    assert(
      validExts.any(lowerName.endsWith),
      'The ${format.name} format name must end with ${validExts.join(' or ')}.',
    );
  }

  void checkCommonParameters({
    required int targetWidth,
    required int targetHeight,
    int quality = 95,
  }) {
    if (targetWidth <= 0) {
      throw ArgumentError.value(
          targetWidth, 'targetWidth', 'must be greater than 0');
    }
    if (targetHeight <= 0) {
      throw ArgumentError.value(
        targetHeight,
        'targetHeight',
        'must be greater than 0',
      );
    }
    if (quality < 0 || quality > 100) {
      throw ArgumentError.value(
          quality, 'quality', 'must be between 0 and 100');
    }
  }

  void checkNumberOfRetries(int numberOfRetries) {
    if (numberOfRetries <= 0) {
      throw ArgumentError.value(
        numberOfRetries,
        'numberOfRetries',
        'must be greater than 0',
      );
    }
  }

  void checkSourceAndTargetPath(String sourcePath, String targetPath) {
    if (sourcePath == targetPath) {
      throw ArgumentError('Target path and source path cannot be the same.');
    }
  }
}
