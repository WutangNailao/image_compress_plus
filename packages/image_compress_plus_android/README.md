# image_compress_plus_android

Android implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on Android.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the Android implementation directly:

```yaml
dependencies:
  image_compress_plus_android: ^2.0.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## Android Support

- Methods: `compressWithList`, `compressAssetImage`, `compressWithFile`, `compressAndGetFile`
- Formats: `jpeg`, `png`, `webp`, `heic`
- Params: `quality`, `rotate`, `inSampleSize`, `keepExif`

## Android Requirements

- Update Kotlin to `1.5.21` or higher if your project is using an older version.
- `heic` uses AndroidX `HeifWriter`, requires Android API 28+ and hardware encoder support.

Reference:

- https://developer.android.com/reference/androidx/heifwriter/HeifWriter
- https://developer.android.com/reference/android/graphics/BitmapFactory.Options#inSampleSize
