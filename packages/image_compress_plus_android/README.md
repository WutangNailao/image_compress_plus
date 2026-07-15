# image_compress_plus_android

Android implementation of `image_compress_plus`.

This package is endorsed and is used by `image_compress_plus` automatically on Android.
Most users should depend on `image_compress_plus` instead of this package directly.

## Usage

Add to your `pubspec.yaml` only if you need to depend on the Android implementation directly:

```yaml
dependencies:
  image_compress_plus_android: ^3.0.0
```

For app-level usage APIs, see:

- https://pub.dev/packages/image_compress_plus
- https://github.com/WuTangNaiLao/image_compress_plus/tree/main/packages/image_compress_plus

## Android Support

- Methods: `compressWithList`, `compressAssetImage`, `compressWithFile`, `compressAndGetFile`
- Output formats: `jpeg`, `png`, `webp`, `heic`
- Params: `quality`, `rotate`, `keepExif`, `numberOfRetries`

## Architecture

The Android implementation now follows the same high-level shape as the iOS package:

- `pigeon` for the Dart/native contract
- a single `CompressionRequest` model
- a unified compression pipeline
- a system-decoder-first input strategy
- four fixed output encoders: `jpeg`, `png`, `webp`, `heic`

## Input Format Support Matrix

Android does not have a single ImageIO-equivalent framework, so input support is best understood as a system stack with fallbacks.

| Layer | Role | Typical Inputs |
| --- | --- | --- |
| `ImageDecoder` | Primary decoder on Android 9+ | `jpeg`, `png`, `webp`, `gif`, `bmp`, `heif/heic`, plus any format supported by the device image stack |
| `BitmapFactory` | Fallback decoder on older devices and decode fallback path | `jpeg`, `png`, `webp`, `gif`, `bmp` and device-dependent legacy support |
| `ExifInterface` | Metadata and rotation source | `jpeg`, `png`, `webp`, `heic`, several RAW containers, and API-dependent extras such as `avif` |

In practice, the plugin is optimized for:

- common raster inputs that decode to a `Bitmap`
- EXIF-aware rotation correction when metadata is available
- consistent conversion into one of the four supported output formats

## Fallback Strategy

The current Android pipeline uses this order:

1. Try `ImageDecoder` on Android 9+ for the broadest modern system support.
2. Fall back to `BitmapFactory` for older Android versions.
3. Read orientation metadata with `ExifInterface` when `autoCorrectionAngle` is enabled.
4. Normalize into a single in-memory bitmap path.
5. Encode only to `jpeg`, `png`, `webp`, or `heic`.
6. On memory pressure, retry with a larger decode sample size until `numberOfRetries` is exhausted.

This keeps Android aligned with the iOS package's design goal:

- accept as many practical system-supported inputs as possible
- constrain outputs to a small, predictable set
- keep metadata handling explicit and stable

The Android host side also reports structured native failures for:

- `unsupported_input_format`
- `decode_failed`
- `unsupported_output_format`
- `encode_failed`
- `file_read_failed` / `transient_file_read_failed`
- `file_write_failed` / `transient_file_write_failed`

## keepExif Semantics

`keepExif` now follows a metadata strategy closer to the iOS implementation:

- preserve metadata on a best-effort basis instead of failing the whole compression request
- normalize output orientation to `normal` when auto-rotation or manual rotation changes the rendered image
- preserve the original orientation only when no transform is applied
- attempt metadata preservation for all four output formats through `ExifInterface` on a best-effort basis
- avoid writing stale thumbnail- and maker-note-style metadata back onto transformed outputs

As with iOS, metadata preservation depends on what the destination format and runtime can actually store. `png`, `webp`, and `heic` should be treated as best-effort rather than guaranteed metadata-preserving outputs. If Android cannot safely re-attach metadata for a given output, the compression result is still returned.

## Unsupported / Version-Dependent Cases

- `heic` output uses AndroidX `HeifWriter` and requires Android API 28+.
- Some input formats are device- and OS-version-dependent even when Android documents platform support at a high level.
- Animated formats are decoded as still images by the current pipeline.
- Formats that do not decode into a `Bitmap` through the Android system stack are not yet supported by this package.

## Android Requirements

- Flutter `3.10.0+`
- Dart `3.0.0+`
- Kotlin `2.2.20+`
- Java 17 target
- Android min SDK 24
- Android compile SDK 36
- `heic` output requires Android API 28+ and compatible encoder support

Reference:

- https://developer.android.com/reference/androidx/heifwriter/HeifWriter
- https://developer.android.com/reference/android/graphics/ImageDecoder
- https://developer.android.com/reference/android/graphics/BitmapFactory.Options#inSampleSize
- https://developer.android.com/reference/androidx/exifinterface/media/ExifInterface
