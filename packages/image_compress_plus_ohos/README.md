# image_compress_plus_ohos

OpenHarmony implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on OpenHarmony.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the OpenHarmony implementation directly:

```yaml
dependencies:
  image_compress_plus_ohos: ^0.1.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## OpenHarmony Support

- Methods: `compressWithList`, `compressAssetImage`, `compressWithFile`, `compressAndGetFile`
- Recommended output formats: `jpeg`, `png`, `webp`
- Params: `quality`, `rotate`

## OpenHarmony Requirements

- Requires OpenHarmony Flutter environment (`flutter_ohos`) and plugin registration.
- Platform capabilities may vary across device vendors and system versions.
