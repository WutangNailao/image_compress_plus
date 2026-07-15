import 'dart:async';
import 'dart:typed_data' as typed_data;

import 'package:flutter/services.dart';
import 'package:image_compress_plus_platform_interface/image_compress_plus_platform_interface.dart';
import 'package:image_compress_plus_web/src/log.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

import 'src/compressor.dart';

class ImageCompressPlusWeb extends ImageCompressPlusPlatform {
  static void registerWith(Registrar registrar) {
    ImageCompressPlusPlatform.instance = ImageCompressPlusWeb();
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
  }) {
    throw UnimplementedError('The method not support web');
  }

  @override
  Future<typed_data.Uint8List?> compressAssetImage(
    String assetName, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    final asset = await rootBundle.load(assetName);
    final buffer = asset.buffer.asUint8List();
    return resizeWithList(
      buffer: buffer,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: quality,
      format: targetFormat,
    );
  }

  @override
  Future<typed_data.Uint8List?> compressWithFile(
    String path, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) {
    throw UnimplementedError('The method not support web');
  }

  @override
  Future<typed_data.Uint8List> compressWithList(
    typed_data.Uint8List image, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
  }) {
    validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    return resizeWithList(
      buffer: image,
      minWidth: targetWidth,
      minHeight: targetHeight,
      quality: quality,
      format: targetFormat,
    );
  }

  @override
  Future<void> showNativeLog(bool value) async {
    showLog = value;
  }

  @override
  ImageCompressPlusValidator get validator => ImageCompressPlusValidator();
}
