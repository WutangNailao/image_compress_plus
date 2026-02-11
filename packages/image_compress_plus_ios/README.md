# image_compress_plus_ios

iOS implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on iOS.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the iOS implementation directly:

```yaml
dependencies:
  image_compress_plus_ios: ^2.0.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## iOS Support

- Methods: `compressWithList`, `compressAssetImage`, `compressWithFile`, `compressAndGetFile`
- Formats: `jpeg`, `png`, `webp`, `heic`
- Params: `quality`, `rotate`, `keepExif`

## iOS Requirements

- Minimum iOS deployment target: `13.0`.
- `heic` requires iOS 13+.
- WebP encoding/decoding uses `SDWebImage` and `SDWebImageWebPCoder`.
