import 'package:cross_file/cross_file.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'dart:typed_data' as typed_data;

import 'src/compress_format.dart';
import 'src/validator.dart';

export 'src/compress_format.dart';
export 'src/errors.dart';
export 'src/validator.dart';
export 'package:cross_file/cross_file.dart';

abstract class ImageCompressPlusPlatform extends PlatformInterface {
  static const _token = Object();

  static ImageCompressPlusPlatform instance = UnsupportedImageCompressPlus();

  ImageCompressPlusPlatform() : super(token: _token);

  ImageCompressPlusValidator get validator;

  Future<void> showNativeLog(bool value);

  Future<typed_data.Uint8List> compressWithList(
    typed_data.Uint8List image, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
  });

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
  });

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
  });

  Future<typed_data.Uint8List?> compressAssetImage(
    String assetName, {
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    CompressFormat targetFormat = CompressFormat.jpeg,
    bool keepExif = false,
  });
}

class UnsupportedImageCompressPlus extends ImageCompressPlusPlatform {
  @override
  Future<typed_data.Uint8List?> compressAssetImage(String assetName,
          {int targetWidth = 1920,
          int targetHeight = 1080,
          int quality = 95,
          int rotate = 0,
          bool autoCorrectionAngle = true,
          CompressFormat targetFormat = CompressFormat.jpeg,
          bool keepExif = false}) =>
      throw UnimplementedError();

  @override
  Future<typed_data.Uint8List?> compressWithFile(String path,
          {int targetWidth = 1920,
          int targetHeight = 1080,
          int quality = 95,
          int rotate = 0,
          bool autoCorrectionAngle = true,
          CompressFormat targetFormat = CompressFormat.jpeg,
          bool keepExif = false,
          int numberOfRetries = 5}) =>
      throw UnimplementedError();

  @override
  Future<XFile?> compressAndGetFile(String path, String targetPath,
          {int targetWidth = 1920,
          int targetHeight = 1080,
          int quality = 95,
          int rotate = 0,
          bool autoCorrectionAngle = true,
          CompressFormat targetFormat = CompressFormat.jpeg,
          bool keepExif = false,
          int numberOfRetries = 5}) =>
      throw UnimplementedError();

  @override
  Future<typed_data.Uint8List> compressWithList(typed_data.Uint8List image,
          {int targetWidth = 1920,
          int targetHeight = 1080,
          int quality = 95,
          int rotate = 0,
          bool autoCorrectionAngle = true,
          CompressFormat targetFormat = CompressFormat.jpeg,
          bool keepExif = false}) =>
      throw UnimplementedError();

  @override
  Future<void> showNativeLog(bool value) => throw UnimplementedError();

  @override
  ImageCompressPlusValidator get validator => throw UnimplementedError();
}
