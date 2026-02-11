// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' as typed_data;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../button.dart';
import 'package:flutter/material.dart' hide TextButton;
import 'package:flutter/services.dart';
import 'package:image_compress_plus/image_compress_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;

import '../benchmark/benchmark_runner.dart';
import '../const/resource.dart';
import '../time_logger.dart';

Future<void> runMain() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
  ImageCompressPlus.showNativeLog = true;
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ImageProvider? provider;
  bool _isBenchmarkRunning = false;
  String? _benchmarkSummary;

  Future<void> compress() async {
    final img = AssetImage('img/img.jpg');
    print('pre compress');
    final config = ImageConfiguration();
    final AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    final beforeCompress = data.lengthInBytes;
    print('beforeCompress = $beforeCompress');
    final result = await ImageCompressPlus.compressWithList(
      data.buffer.asUint8List(),
    );
    print('after = ${result.length}');
  }

  Future<Directory> getTemporaryDirectory() async {
    return Directory.systemTemp;
  }

  void _testCompressFile() async {
    final img = AssetImage('img/img.jpg');
    print('pre compress');
    final config = ImageConfiguration();
    final AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    final dir = await path_provider.getTemporaryDirectory();
    final File file = createFile('${dir.absolute.path}/test.png');
    file.writeAsBytesSync(data.buffer.asUint8List());

    final result = await testCompressFile(file);
    if (result == null) return;

    safeSetState(() {
      provider = MemoryImage(result);
    });
  }

  File createFile(String path) {
    final file = File(path);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
    }
    return file;
  }

  Future<String> getExampleFilePath() async {
    final img = AssetImage('img/img.jpg');
    print('pre compress');
    final config = ImageConfiguration();
    final AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    final dir = await path_provider.getTemporaryDirectory();
    final File file = createFile('${dir.absolute.path}/test.png');
    file.createSync(recursive: true);
    file.writeAsBytesSync(data.buffer.asUint8List());
    return file.absolute.path;
  }

  void getFileImage() async {
    final img = AssetImage('img/img.jpg');
    print('pre compress');
    final config = ImageConfiguration();
    final AssetBundleImageKey key = await img.obtainKey(config);
    final ByteData data = await key.bundle.load(key.name);
    final dir = await path_provider.getTemporaryDirectory();
    final File file = createFile('${dir.absolute.path}/test.png');
    file.writeAsBytesSync(data.buffer.asUint8List());
    final targetPath = dir.absolute.path + '/temp.jpg';
    final imgFile = await testCompressAndGetFile(file, targetPath);
    if (imgFile == null) {
      return;
    }
    safeSetState(() {
      provider = XFileImageProvider(imgFile);
    });
  }

  Future<typed_data.Uint8List?> testCompressFile(File file) async {
    print('testCompressFile');
    final result = await ImageCompressPlus.compressWithFile(
      file.absolute.path,
      minWidth: 2300,
      minHeight: 1500,
      quality: 94,
      rotate: 180,
    );
    print(file.lengthSync());
    print(result?.length);
    return result;
  }

  Future<XFile?> testCompressAndGetFile(File file, String targetPath) async {
    print('testCompressAndGetFile');
    final result = await ImageCompressPlus.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 90,
      minWidth: 1024,
      minHeight: 1024,
      rotate: 90,
    );

    if (result == null) return null;

    final bytes = await result.readAsBytes();

    print(
      'The src file size: ${file.lengthSync()}, '
      'the result bytes length: ${bytes.length}',
    );
    return result;
  }

  Future testCompressAsset(String assetName) async {
    print('testCompressAsset');
    final list = await ImageCompressPlus.compressAssetImage(
      assetName,
      minHeight: 1920,
      minWidth: 1080,
      quality: 96,
      rotate: 135,
    );
    if (list == null) return;
    safeSetState(() {
      provider = MemoryImage(typed_data.Uint8List.fromList(list));
    });
  }

  Future compressListExample() async {
    final data = await rootBundle.load('img/img.jpg');
    final memory = await testComporessList(data.buffer.asUint8List());
    safeSetState(() {
      provider = MemoryImage(memory);
    });
  }

  Future<typed_data.Uint8List> testComporessList(
    typed_data.Uint8List list,
  ) async {
    final result = await ImageCompressPlus.compressWithList(
      list,
      minHeight: 1080,
      minWidth: 1080,
      quality: 96,
      rotate: 270,
      format: CompressFormat.webp,
    );
    print(list.length);
    print(result.length);
    return result;
  }

  Future<void> writeToFile(List<int> list, String filePath) {
    return File(filePath).writeAsBytes(list, flush: true);
  }

  void _compressAssetAndAutoRotate() async {
    final result = await ImageCompressPlus.compressAssetImage(
      R.IMG_AUTO_ANGLE_JPG,
      minWidth: 1000,
      quality: 95,
      // autoCorrectionAngle: false,
    );
    if (result == null) return;
    safeSetState(() {
      provider = MemoryImage(typed_data.Uint8List.fromList(result));
    });
  }

  void _compressPngImage() async {
    final result = await ImageCompressPlus.compressAssetImage(
      R.IMG_HEADER_PNG,
      minWidth: 300,
      minHeight: 500,
    );
    if (result == null) return;
    safeSetState(() {
      provider = MemoryImage(typed_data.Uint8List.fromList(result));
    });
  }

  void _compressTransPNG() async {
    final bytes = await getAssetImageUint8List(
      R.IMG_TRANSPARENT_BACKGROUND_PNG,
    );
    final result = await ImageCompressPlus.compressWithList(
      bytes,
      minHeight: 100,
      minWidth: 100,
      format: CompressFormat.png,
    );
    final u8list = typed_data.Uint8List.fromList(result);
    safeSetState(() {
      provider = MemoryImage(u8list);
    });
  }

  void _restoreTransPNG() async {
    setState(() {
      provider = AssetImage(R.IMG_TRANSPARENT_BACKGROUND_PNG);
    });
  }

  void _compressImageAndKeepExif() async {
    final result = await ImageCompressPlus.compressAssetImage(
      R.IMG_AUTO_ANGLE_JPG,
      minWidth: 500,
      minHeight: 600,
      // autoCorrectionAngle: false,
      keepExif: true,
    );
    if (result == null) return;
    safeSetState(() {
      provider = MemoryImage(typed_data.Uint8List.fromList(result));
    });
  }

  /// The example for compressing heic format.
  ///
  /// Convert jpeg to heic format, and then convert heic to jpg format.
  ///
  /// Show the file path and size in the console.
  void _compressHeicExample() async {
    if (!(Platform.isAndroid || Platform.isIOS)) {
      print('HEIC is only supported on Android and iOS.');
      return;
    }
    print('start compress');
    final logger = TimeLogger();
    logger.startRecorder();
    final String? tmpDir;
    if (Platform.isAndroid) {
      tmpDir = (await path_provider.getExternalStorageDirectories())
          ?.first
          .absolute
          .path;
    } else if (Platform.isIOS) {
      tmpDir = (await path_provider.getTemporaryDirectory()).path;
    } else {
      tmpDir = null;
    }

    if (tmpDir == null) {
      print('tmpDir is null');
      print(
          'You need check your permission for the external storage on Android.');
      return;
    }

    final target = '$tmpDir/${DateTime.now().millisecondsSinceEpoch}.heic';
    final srcPath = await getExampleFilePath();
    final result = await ImageCompressPlus.compressAndGetFile(
      srcPath,
      target,
      format: CompressFormat.heic,
      quality: 90,
    );
    if (result == null) return;

    print('Compress heic success.');
    logger.logTime();
    print('src, path = $srcPath length = ${File(srcPath).lengthSync()}');

    print(
      'Compress heic result path: ${result.path}, '
      'size: ${await result.length()}',
    );

    // Convert heic to jpg
    final jpgPath =
        '$tmpDir/heic-to-jpg-${DateTime.now().millisecondsSinceEpoch}.jpg';
    try {
      final jpgResult = await ImageCompressPlus.compressAndGetFile(
        result.path,
        jpgPath,
        format: CompressFormat.jpeg,
        quality: 90,
      );
      if (jpgResult == null) {
        print('Convert heic to jpg failed.');
      } else {
        print(
          'Convert heic to jpg success. '
          'Jpg path: ${jpgResult.path}, '
          'size: ${await jpgResult.length()}',
        );
      }
    } catch (e) {
      print('Error: $e');
      print('Convert heic to jpg failed.');
    }
  }

  void _compressWebpExample() async {
    // WebP supported on Android/iOS/Linux/Windows.
    final logger = TimeLogger();
    logger.startRecorder();
    print('start compress webp');
    final quality = 90;
    final tmpDir = (await getTemporaryDirectory()).path;
    final target =
        '$tmpDir/${DateTime.now().millisecondsSinceEpoch}-$quality.webp';
    final srcPath = await getExampleFilePath();
    final result = await ImageCompressPlus.compressAndGetFile(
      srcPath,
      target,
      format: CompressFormat.webp,
      minHeight: 800,
      minWidth: 800,
      quality: quality,
    );
    if (result == null) return;
    print('Compress webp success.');
    logger.logTime();
    print('src, path = $srcPath length = ${File(srcPath).lengthSync()}');
    print(
      'Compress webp result path: ${result.path}, '
      'size: ${await result.length()}',
    );
    safeSetState(() {
      provider = XFileImageProvider(result);
    });
  }

  void _compressFromWebPImage() async {
    // Converting webp to jpeg
    final result = await ImageCompressPlus.compressAssetImage(
      R.IMG_ICON_WEBP,
    );
    if (result == null) return;
    // Show result image
    safeSetState(() {
      provider = MemoryImage(typed_data.Uint8List.fromList(result));
    });
  }

  Future<void> _runPerformanceBenchmark() async {
    if (_isBenchmarkRunning) {
      return;
    }

    safeSetState(() {
      _isBenchmarkRunning = true;
      _benchmarkSummary = 'Benchmark running...';
    });

    try {
      final imageData = await rootBundle.load(R.IMG_IMG_JPG);
      final sourceBytes = imageData.buffer.asUint8List();
      final tmpDir = await path_provider.getTemporaryDirectory();
      final sourcePath = '${tmpDir.path}/benchmark-source.jpg';
      final sourceFile = createFile(sourcePath);
      sourceFile.writeAsBytesSync(sourceBytes, flush: true);

      final result = await BenchmarkRunner.run(
        sourceBytes: sourceBytes,
        sourcePath: sourcePath,
        temporaryDirectoryPath: tmpDir.path,
      );

      final reportPath = '${tmpDir.path}/image-compress-plus-benchmark-'
          '${DateTime.now().millisecondsSinceEpoch}.json';
      final reportJson = JsonEncoder.withIndent('  ').convert(result.toJson());
      await File(reportPath).writeAsString(reportJson, flush: true);

      final summary = '${result.toPrettyText()}\njson: $reportPath';
      print(summary);
      safeSetState(() {
        _benchmarkSummary = summary;
      });
    } catch (e, s) {
      final msg = 'Benchmark failed: $e';
      print(msg);
      print(s);
      safeSetState(() {
        _benchmarkSummary = msg;
      });
    } finally {
      safeSetState(() {
        _isBenchmarkRunning = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Plugin example app')),
        body: SafeArea(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: AspectRatio(
                  aspectRatio: 1 / 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(border: Border.all(width: 2)),
                    child: Image(
                      image: provider ?? AssetImage('img/img.jpg'),
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text('Platform: ${Platform.operatingSystem}'),
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('CompressFile and rotate 180'),
                  onPressed: _testCompressFile,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('CompressAndGetFile and rotate 90'),
                  onPressed: getFileImage,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('CompressAsset and rotate 135'),
                  onPressed: () => testCompressAsset('img/img.jpg'),
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('CompressList and rotate 270'),
                  onPressed: compressListExample,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('test compress auto angle'),
                  onPressed: _compressAssetAndAutoRotate,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Test png '),
                  onPressed: _compressPngImage,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Format transparent PNG'),
                  onPressed: _compressTransPNG,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Restore transparent PNG'),
                  onPressed: _restoreTransPNG,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Keep exif image'),
                  onPressed: _compressImageAndKeepExif,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Convert to heic format and print the file url'),
                  onPressed: _compressHeicExample,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Convert to webp format'),
                  onPressed: _compressWebpExample,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text('Convert from webp format'),
                  onPressed: _compressFromWebPImage,
                ),
              ),
              SliverToBoxAdapter(
                child: TextButton(
                  child: Text(
                    _isBenchmarkRunning
                        ? 'Performance benchmark running...'
                        : 'Run performance benchmark',
                  ),
                  onPressed: _runPerformanceBenchmark,
                ),
              ),
              if (_benchmarkSummary != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    child: SelectableText(_benchmarkSummary!),
                  ),
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.settings_backup_restore),
          onPressed: () => setState(() => provider = null),
          tooltip: 'Show default asset',
        ),
      ),
    );
  }
}

Future<typed_data.Uint8List> getAssetImageUint8List(String key) async {
  final byteData = await rootBundle.load(key);
  return byteData.buffer.asUint8List();
}

double calcScale({
  required double srcWidth,
  required double srcHeight,
  required double minWidth,
  required double minHeight,
}) {
  final scaleW = srcWidth / minWidth;
  final scaleH = srcHeight / minHeight;

  final scale = math.max(1.0, math.min(scaleW, scaleH));

  return scale;
}

extension _StateExtension on State {
  /// [setState] when it's not building, then wait until next frame built.
  FutureOr<void> safeSetState(FutureOr<dynamic> Function() fn) async {
    await fn();
    if (mounted &&
        !context.debugDoingBuild &&
        context.owner?.debugBuilding == false) {
      // ignore: invalid_use_of_protected_member
      setState(() {});
    }
    final Completer<void> completer = Completer<void>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      completer.complete();
    });
    return completer.future;
  }
}

class XFileImageProvider extends ImageProvider<XFileImageProvider> {
  const XFileImageProvider(this.file);

  final XFile file;

  @override
  Future<XFileImageProvider> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture(this);
  }

  Future<ui.Codec> _loadAsync(
    XFileImageProvider key,
    DecoderBufferCallback decode,
  ) async {
    final bytes = await file.readAsBytes();
    final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  ImageStreamCompleter loadBuffer(
    XFileImageProvider key,
    DecoderBufferCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _loadAsync(key, decode),
      scale: 1.0,
      informationCollector: () sync* {
        yield ErrorDescription('Path: ${file.path}');
      },
    );
  }

  @override
  bool operator ==(Object other) {
    if (other.runtimeType != runtimeType) return false;
    return other is XFileImageProvider && file.path == other.file.path;
  }

  @override
  int get hashCode => file.path.hashCode;

  @override
  String toString() => '$runtimeType("${file.path}")';
}
