// ignore_for_file: require_trailing_commas

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_compress_plus_platform_interface/image_compress_plus_platform_interface.dart';

class ImageCompressPlusWindows extends ImageCompressPlusPlatform {
  static const _channel = MethodChannel('image_compress_plus');

  @override
  ImageCompressPlusValidator get validator => _validator;
  final ImageCompressPlusValidator _validator = ImageCompressPlusValidator();

  static void registerWith() {
    ImageCompressPlusPlatform.instance = ImageCompressPlusWindows();
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
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    final img = AssetImage(assetName);
    const config = ImageConfiguration();
    final AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    final uint8List = data.buffer.asUint8List();
    if (uint8List.isEmpty) {
      return null;
    }
    return compressWithList(
      uint8List,
      targetHeight: targetHeight,
      targetWidth: targetWidth,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: targetFormat,
      keepExif: keepExif,
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
    final result = await _channel.invokeMethod('compressWithFile', [
      path,
      targetWidth,
      targetHeight,
      quality,
      rotate,
      autoCorrectionAngle,
      _convertTypeToInt(targetFormat),
      keepExif,
      1,
      numberOfRetries,
    ]);
    return result;
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
  }) async {
    if (image.isEmpty) {
      throw CompressError('The image is empty.');
    }
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    final result = await _channel.invokeMethod('compressWithList', [
      image,
      targetWidth,
      targetHeight,
      quality,
      rotate,
      autoCorrectionAngle,
      _convertTypeToInt(targetFormat),
      keepExif,
      1,
    ]);
    return result;
  }

  @override
  Future<void> showNativeLog(bool value) async {
    await _channel.invokeMethod('showLog', value);
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
    final String? result =
        await _channel.invokeMethod('compressWithFileAndGetFile', [
      path,
      targetWidth,
      targetHeight,
      quality,
      targetPath,
      rotate,
      autoCorrectionAngle,
      _convertTypeToInt(targetFormat),
      keepExif,
      1,
      numberOfRetries,
    ]);
    if (result == null) {
      return null;
    }
    return XFile(result);
  }

  int _convertTypeToInt(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 0;
      case CompressFormat.png:
        return 1;
      case CompressFormat.heic:
        return 2;
      case CompressFormat.webp:
        return 3;
    }
  }
}
