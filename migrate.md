# Migrate document

## 2.x to 3.0.0

There are several breaking changes in 3.0.0:

- Package name changed from `flutter_image_compress` to `image_compress_plus`.
- Import path changed from `flutter_image_compress.dart` to `image_compress_plus.dart`.
- The implementation package was split to federated platform packages (`image_compress_plus_android`, `image_compress_plus_ios`, `image_compress_plus_linux`, `image_compress_plus_windows`, etc.).
- Android plugin namespace changed to `world.nailao.image_compress_plus`.

### Before (2.x)

```yaml
dependencies:
  flutter_image_compress: ^2.4.0
```

```dart
import 'package:flutter_image_compress/flutter_image_compress.dart';
```

### After (3.0.0)

```yaml
dependencies:
  image_compress_plus: ^3.0.0
```

```dart
import 'package:image_compress_plus/image_compress_plus.dart';
```

## 1.x to 2.x

There are several changes

- The return value of `File` is now changed to the `XFile` type of [cross_file][], so you need to change the code to `XFile`.

1.0:

```dart
final File file = ImageCompressPlus.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: 1024,
      minHeight: 1024,
      rotate: 90,
    );

int length = file.lengthSync();
Uint8List buffer = file.readAsBytesSync();
```

2.0:

```dart
final XFile file = await ImageCompressPlus.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: 1024,
      minHeight: 1024,
      rotate: 90,
    );

int length = await file.length();
Uint8List buffer = await file.readAsBytes();
```

Other usage of `XFile` to see [document][xfile]

[cross_file]: https://pub.dev/packages/cross_file
[xfile]: https://pub.dev/documentation/cross_file/latest/cross_file/XFile-class.html
