## 3.0.0

- **BREAKING**: Replace the legacy MethodChannel handler chain with a `pigeon`-based host API.
- **BREAKING**: Rebuild Android processing around a unified compression pipeline with four fixed output encoders: `jpeg`, `png`, `webp`, and `heic`.
- **BREAKING**: Remove the old `CompressFileHandler` / `CompressListHandler` / `FormatRegister` / `CommonHandler` / `HeifHandler` architecture.
- **BREAKING**: Raise the Android toolchain requirements to min SDK 24, compile SDK 36, Kotlin 2.2.20, and Java 17.
- **FEAT**: Prefer `ImageDecoder` on Android 9+ and fall back to `BitmapFactory` on older devices.
- **FEAT**: Add documented input format capability and fallback strategy for Android.

## 2.0.0

- **BREAKING**: major version bump to align with image_compress_plus 3.0.0.
- **BREAKING**: Android plugin namespace updated to world.nailao.image_compress_plus.

## 1.0.6

- **DEPS**: Bump `compileSdk` to `34`.

## 1.0.5

 - **DOCS**: The first version for OpenHarmony. ([5fcab8da](https://github.com/fluttercandies/flutter_image_compress/commit/5fcab8dac6277b36b7169962474e5af3cf88724b))

## 1.0.4

- **DEPS**: Bump KGP (Kotlin Gradle Plugin) to `1.8.20`.
- **DEPS**: Bump Java source compatibility and the JVM target to `11.`

## 1.0.3

 - **DOCS**: Update README ([#266](https://github.com/fluttercandies/flutter_image_compress/issues/266)). ([235643ab](https://github.com/fluttercandies/flutter_image_compress/commit/235643ab0be9c9a39083031d9ab9de06a74241f3))
 - **DOCS**: Update changelog. ([c847f5d5](https://github.com/fluttercandies/flutter_image_compress/commit/c847f5d5d03d4e727b1a83dd33e54d8d93787749))

## 1.0.2

 - **DOCS**: Update changelog. ([c847f5d5](https://github.com/fluttercandies/flutter_image_compress/commit/c847f5d5d03d4e727b1a83dd33e54d8d93787749))

## 1.0.1

- Change sdk constraint to `>=2.12.0 <4.0.0`.

## 1.0.0

- The first version for migrate to platform interface.
