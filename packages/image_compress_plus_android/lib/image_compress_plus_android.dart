// ignore_for_file: require_trailing_commas

import 'dart:async';
import 'dart:io';
import 'dart:typed_data' as typed_data;

import 'package:flutter/material.dart';
import 'package:image_compress_plus_platform_interface/image_compress_plus_platform_interface.dart';

import 'messages.g.dart';

class ImageCompressPlusAndroid extends ImageCompressPlusPlatform {
  final ImageCompressPlusHostApi _hostApi = ImageCompressPlusHostApi();

  @override
  ImageCompressPlusValidator get validator => _validator;
  final ImageCompressPlusValidator _validator = ImageCompressPlusValidator();

  static void registerWith() {
    ImageCompressPlusPlatform.instance = ImageCompressPlusAndroid();
  }

  @override
  Future<typed_data.Uint8List?> compressAssetImage(String assetName,
      {int targetWidth = 1920,
      int targetHeight = 1080,
      int quality = 95,
      int rotate = 0,
      bool autoCorrectionAngle = true,
      CompressFormat targetFormat = CompressFormat.jpeg,
      bool keepExif = false}) async {
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    final img = AssetImage(assetName);
    const config = ImageConfiguration();
    final AssetBundleImageKey key = await img.obtainKey(config);
    final typed_data.ByteData data = await key.bundle.load(key.name);
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
    return _hostApi.compressWithFile(
      path: path,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: _convertTypeToHostFormat(targetFormat),
      keepExif: keepExif,
      numberOfRetries: numberOfRetries,
    );
  }

  @override
  Future<typed_data.Uint8List> compressWithList(typed_data.Uint8List image,
      {int targetWidth = 1920,
      int targetHeight = 1080,
      int quality = 95,
      int rotate = 0,
      bool autoCorrectionAngle = true,
      CompressFormat targetFormat = CompressFormat.jpeg,
      bool keepExif = false}) async {
    if (image.isEmpty) {
      throw CompressError('The image is empty.');
    }
    _validator.checkCommonParameters(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
    );
    return _hostApi.compressWithList(
      image: image,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: _convertTypeToHostFormat(targetFormat),
      keepExif: keepExif,
    );
  }

  @override
  Future<void> showNativeLog(bool value) async {
    await _hostApi.showLog(value);
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
    final String? result = await _hostApi.compressWithFileAndGetFile(
      path: path,
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      targetPath: targetPath,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: _convertTypeToHostFormat(targetFormat),
      keepExif: keepExif,
      numberOfRetries: numberOfRetries,
    );
    if (result == null) {
      return null;
    }
    return XFile(result);
  }

  HostFormat _convertTypeToHostFormat(CompressFormat format) {
    return switch (format) {
      CompressFormat.jpeg => HostFormat.jpeg,
      CompressFormat.png => HostFormat.png,
      CompressFormat.heic => HostFormat.heic,
      CompressFormat.webp => HostFormat.webp,
    };
  }
}
