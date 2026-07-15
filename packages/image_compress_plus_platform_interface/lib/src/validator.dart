import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import 'compress_format.dart';

class ImageCompressPlusValidator {
  ImageCompressPlusValidator(this.channel);

  final MethodChannel channel;

  bool ignoreCheckExtName = false;
  bool ignoreCheckSupportPlatform = false;

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

  Future<bool> checkSupportPlatform(CompressFormat format) async {
    if (ignoreCheckSupportPlatform) {
      return true;
    }
    if (format == CompressFormat.heic) {
      if (Platform.isIOS) {
        final String version = await channel.invokeMethod('getSystemVersion');
        final firstVersion = version.split('.')[0];
        final result = int.parse(firstVersion) >= 13;
        const msg = 'The heic format only supports iOS 13.0+';
        assert(result, msg);
        _checkThrowError(result, msg);
        return result;
      } else if (Platform.isAndroid) {
        final int version = await channel.invokeMethod('getSystemVersion');
        final result = version >= 28;
        const msg = 'The heic format only supports Android API 28+';
        assert(result, msg);
        _checkThrowError(result, msg);
        return result;
      } else {
        const msg = 'The heic format only supports Android and iOS.';
        assert(Platform.isAndroid || Platform.isIOS, msg);
        _checkThrowError(false, msg);
        return false;
      }
    } else if (format == CompressFormat.webp) {
      if (Platform.isAndroid ||
          Platform.isIOS ||
          Platform.isLinux ||
          Platform.isWindows) {
        return true;
      }
      const msg =
          'The webp format only supports Android, iOS, Linux, and Windows.';
      _checkThrowError(false, msg);
      return false;
    }
    return true;
  }

  void _checkThrowError(bool result, String msg) {
    if (!result) {
      throw UnsupportedError(msg);
    }
  }
}
