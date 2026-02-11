# image_compress_plus_example

Demonstrates how to use the image_compress_plus plugin.

## Getting Started

For help getting started with Flutter, view our online
[documentation](https://flutter.io/).

## Linux / Windows

1. Install system dependencies:
   - Linux: `libjpeg-turbo`, `libpng`, `libwebp`, `exiv2`
   - Windows (vcpkg): `libjpeg-turbo`, `libpng`, `libwebp`, `exiv2`
2. Run:
   - Linux: `flutter run -d linux`
   - Windows: `flutter run -d windows`

The example UI includes buttons for `compressWithList`, `compressWithFile`, and
`compressAndGetFile`, plus WebP and EXIF tests.

It also includes a `Run performance benchmark` button. The benchmark runs
`compressWithList`, `compressWithFile`, and `compressAndGetFile` test cases,
prints average/P95 latency, total elapsed time, and sequential-vs-parallel
concurrency probe metrics in logs, plus batch-throughput metrics (`N=50` total,
throughput, P95 completion time, failure rate) by format/quality/concurrency,
and writes a JSON report into the
temporary directory.
