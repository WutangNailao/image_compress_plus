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
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) {
    throw UnimplementedError('The method not support web');
  }

  @override
  Future<typed_data.Uint8List?> compressAssetImage(
    String assetName, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) async {
    final asset = await rootBundle.load(assetName);
    final buffer = asset.buffer.asUint8List();
    return resizeWithList(
      buffer: buffer,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
    );
  }

  @override
  Future<typed_data.Uint8List?> compressWithFile(
    String path, {
    int minWidth = 1920,
    int minHeight = 1080,
    int inSampleSize = 1,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  }) {
    throw UnimplementedError('The method not support web');
  }

  @override
  Future<typed_data.Uint8List> compressWithList(
    typed_data.Uint8List image, {
    int minWidth = 1920,
    int minHeight = 1080,
    int quality = 95,
    int rotate = 0,
    int inSampleSize = 1,
    bool autoCorrectionAngle = true,
    CompressFormat format = CompressFormat.jpeg,
    bool keepExif = false,
  }) {
    return resizeWithList(
      buffer: image,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      format: format,
    );
  }

  @override
  void ignoreCheckSupportPlatform(bool bool) {}

  @override
  Future<void> showNativeLog(bool value) async {
    showLog = value;
  }

  @override
  ImageCompressPlusValidator get validator =>
      _ImageCompressPlusValidator();
}

class _ImageCompressPlusValidator extends ImageCompressPlusValidator {
  _ImageCompressPlusValidator()
      : super(
          const MethodChannel('image_compress_plus'),
        );

  @override
  void checkFileNameAndFormat(String name, CompressFormat format) {}
  @override
  Future<bool> checkSupportPlatform(CompressFormat format) async {
    return true;
  }
}
