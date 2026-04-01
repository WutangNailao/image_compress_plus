## 3.0.0

- **BREAKING**: raised minimum iOS deployment target to `13.0`.
- **BREAKING**: bumped package version to `3.0.0` and raised Dart/Flutter toolchain requirements.
- **BREAKING**: migrated the iOS implementation from `MethodChannel` handlers to a Pigeon host API.
- **DEPS**: bumped `image_compress_plus_platform_interface` to `2.1.0` and adopted the new API surface.
- **REFACTOR**: rebuilt the iOS compression flow around request/support/compressor modules.
- **PERF**: unified internal image processing to pixel semantics with `scale = 1`.
- **PERF**: merged normalize/resize/rotate into a single geometry render pass.
- **PERF**: improved WebP decoding with target-size thumbnail decode.
- **FIX**: corrected pixel size fallback for scaled `UIImage` inputs.
- **FEAT**: supported single-edge target resizing semantics.
- **FEAT**: preserved metadata more completely while stripping conflicting fields.
- **FEAT**: added retriable file operations and stable/transient filesystem errors.

## 2.0.0

- **BREAKING**: major version bump to align with image_compress_plus 3.0.0.

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
