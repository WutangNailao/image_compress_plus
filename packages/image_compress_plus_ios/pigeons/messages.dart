import 'package:pigeon/pigeon.dart';

// same with the interface in image_compress_plus_platform_interface.dart, but with some parameters removed and some parameters' types changed to be supported by pigeon.
enum HostFormat {
  jpeg,
  png,
  webp,
  heic,
}

/// Run with:
/// flutter pub run pigeon \
///   --input pigeons/messages.dart
@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'image_compress_plus_ios',
    dartOut: 'lib/messages.g.dart',
    swiftOut: 'ios/Classes/Messages.g.swift',
  ),
)
@HostApi()
abstract class ImageCompressPlusHostApi {
  @async
  Uint8List compressWithList({
    required Uint8List image,
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    HostFormat targetFormat = HostFormat.jpeg,
    bool keepExif = false,
  });

  @async
  Uint8List? compressWithFile({
    required String path,
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    HostFormat targetFormat = HostFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  });

  @async
  String? compressWithFileAndGetFile({
    required String path,
    int targetWidth = 1920,
    int targetHeight = 1080,
    int quality = 95,
    required String targetPath,
    int rotate = 0,
    bool autoCorrectionAngle = true,
    HostFormat targetFormat = HostFormat.jpeg,
    bool keepExif = false,
    int numberOfRetries = 5,
  });

  @async
  void showLog(bool value);
}
