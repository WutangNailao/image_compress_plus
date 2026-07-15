import 'package:pigeon/pigeon.dart';

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
    dartPackageName: 'image_compress_plus_android',
    dartOut: 'lib/messages.g.dart',
    kotlinOut:
        'android/src/main/kotlin/world/nailao/image_compress_plus/Messages.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'world.nailao.image_compress_plus',
    ),
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
