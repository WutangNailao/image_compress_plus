# image_compress_plus (Repository)

Monorepo for `image_compress_plus`, a community-maintained fork of `flutter_image_compress`.

This repository focuses on:

- long-term maintenance and dependency/toolchain upgrades,
- native performance optimization across platforms,
- federated plugin architecture and platform isolation,
- consistent release and migration docs.

## Where To Start

- End-user package docs: `packages/image_compress_plus/README.md`
- Migration notes: `migrate.md`
- Workspace release notes: `CHANGELOG.md`

## Repository Structure

- `packages/image_compress_plus`: main federated plugin package
- `packages/image_compress_plus_platform_interface`: shared platform interface
- `packages/image_compress_plus_android`: Android implementation
- `packages/image_compress_plus_ios`: iOS implementation
- `packages/image_compress_plus_linux`: Linux implementation
- `packages/image_compress_plus_windows`: Windows implementation
- `packages/image_compress_plus_macos`: macOS implementation
- `packages/image_compress_plus_web`: Web implementation
- `packages/image_compress_plus_ohos`: OpenHarmony implementation

## Local Development

Prerequisites:

- Flutter SDK (or `fvm`)
- Dart SDK
- Melos (`dart pub global activate melos`)

Common commands:

```bash
melos run get
melos run analyze
melos run test
melos run format
```

Platform smoke builds:

```bash
melos run try_build_apk
melos run try_build_ios
melos run try_build_web
melos run try_build_macos
```

## Release Workflow (Federated)

Recommended publish order:

1. `image_compress_plus_platform_interface`
2. platform implementations (`android`, `ios`, `linux`, `windows`, `macos`, `web`, `ohos`)
3. `image_compress_plus` main package

Before publishing each package:

```bash
flutter pub publish --dry-run
```

## Notes

- This README is repository-focused.
- API usage examples are intentionally kept in package-level READMEs.
