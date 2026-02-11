# image_compress_plus_web

Web implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on Web.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the web implementation directly:

```yaml
dependencies:
  image_compress_plus_web: ^0.2.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## Web Support

- Methods: `compressWithList`, `compressAssetImage`
- Formats: `jpeg`, `png`, `webp`
- `compressWithFile` and `compressAndGetFile` are not supported on Web.
- `heic` is not supported on Web.

## Web Requirements

- Relies on browser canvas APIs (`toBlob`) for encoding.
- Browser capability differs by format and browser version.
