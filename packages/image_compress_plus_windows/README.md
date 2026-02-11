# image_compress_plus_windows

Windows implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on Windows.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the Windows implementation directly:

```yaml
dependencies:
  image_compress_plus_windows: ^2.0.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## Windows Support

- Methods: `compressWithList`, `compressAssetImage`, `compressWithFile`, `compressAndGetFile`
- Formats: `jpeg`, `png`, `webp`
- Params: `quality`, `rotate`, `keepExif`

## Windows Requirements

This plugin uses native desktop libraries via vcpkg:

- `libjpeg-turbo`
- `libpng`
- `libwebp`
- `exiv2`
