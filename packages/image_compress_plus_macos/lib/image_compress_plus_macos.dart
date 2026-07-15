// ignore: unnecessary_import
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:image_compress_plus_platform_interface/image_compress_plus_platform_interface.dart';

class ImageCompressPlusMacos extends ImageCompressPlusPlatform {
  static const _channel = MethodChannel('image_compress_plus');

  /// For flutter plugin registration.
  static void registerWith() {
    ImageCompressPlusPlatform.instance = ImageCompressPlusMacos();
  }

  @override
  Future<XFile?> compressAndGetFile(
    String path,
    String targetPath, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    _validator.checkNumberOfRetries(numberOfRetries);
    if (!File(path).existsSync()) {
      throw CompressError('Image file does not exist in $path.');
    }
    _validator.checkSourceAndTargetPath(path, targetPath);
    _validator.checkFileNameAndFormat(targetPath, targetFormat);
    final dstPath = await _channel.invokeMethod('compressAndGetFile', {
      'path': path,
      'targetPath': targetPath,
      'minWidth': targetWidth,
      'minHeight': targetHeight,
      'inSampleSize': 1,
      'quality': quality,
      'rotate': rotate,
      'autoCorrectionAngle': autoCorrectionAngle,
      'format': targetFormat.index,
      'keepExif': keepExif,
      'numberOfRetries': numberOfRetries,
    });

    if (dstPath == null) {
      return null;
    }

    return XFile(dstPath);
  }

  @override
  Future<Uint8List?> compressAssetImage(
    String assetName, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    final bytes = await rootBundle
        .load(assetName)
        .then((value) => value.buffer.asUint8List());

    return compressWithList(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: targetFormat,
      keepExif: keepExif,
    );
  }

  @override
  Future<Uint8List?> compressWithFile(
    String path, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) async {
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    _validator.checkNumberOfRetries(numberOfRetries);
    if (!File(path).existsSync()) {
      throw CompressError('Image file does not exist in $path.');
    }
    final result = await _channel.invokeMethod('compressWithFile', {
      'path': path,
      'minWidth': targetWidth,
      'minHeight': targetHeight,
      'inSampleSize': 1,
      'quality': quality,
      'rotate': rotate,
      'autoCorrectionAngle': autoCorrectionAngle,
      'format': targetFormat.index,
      'keepExif': keepExif,
      'numberOfRetries': numberOfRetries,
    });

    if (result == null) {
      return null;
    }

    return result;
  }

  @override
  Future<Uint8List> compressWithList(
    Uint8List image, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    if (image.isEmpty) {
      throw CompressError('The image is empty.');
    }
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    final result = await _channel.invokeMethod<Uint8List>('compressWithList', {
      'list': image,
      'minWidth': targetWidth,
      'minHeight': targetHeight,
      'inSampleSize': 1,
      'quality': quality,
      'rotate': rotate,
      'autoCorrectionAngle': autoCorrectionAngle,
      'format': targetFormat.index,
      'keepExif': keepExif,
    });

    if (result == null) {
      throw Exception('Compress failed');
    }

    return result;
  }

  @override
  Future<void> showNativeLog(bool value) async {
    await _channel.invokeMethod('showLog', value);
  }

  @override
  ImageCompressPlusValidator get validator => _validator;
  final ImageCompressPlusValidator _validator = ImageCompressPlusValidator();
}
