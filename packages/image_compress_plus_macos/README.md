# image_compress_plus_macos

macOS implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on macOS.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the macOS implementation directly:

```yaml
dependencies:
  image_compress_plus_macos: ^2.0.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## macOS Support

- Methods: `compressWithList`, `compressAssetImage`, `compressWithFile`, `compressAndGetFile`
- Formats: `jpeg`, `png`, `heic`
- Params: `quality`, `rotate`, `keepExif`

## macOS Requirements

- Minimum macOS deployment target: `10.15`.
