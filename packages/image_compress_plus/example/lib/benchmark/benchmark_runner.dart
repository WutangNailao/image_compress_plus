import 'dart:typed_data' as typed_data;

import 'package:image_compress_plus/image_compress_plus.dart';

enum BenchmarkMethod {
  compressWithList,
  compressWithFile,
  compressAndGetFile,
}

class BenchmarkCase {
  const BenchmarkCase({
    required this.name,
    required this.method,
    required this.format,
    required this.quality,
    required this.minWidth,
    required this.minHeight,
    this.inSampleSize = 2,
    this.rotate = 0,
  });

  final String name;
  final BenchmarkMethod method;
  final CompressFormat format;
  final int quality;
  final int minWidth;
  final int minHeight;
  final int inSampleSize;
  final int rotate;
}

class BenchmarkCaseResult {
  const BenchmarkCaseResult({
    required this.name,
    required this.method,
    required this.format,
    required this.quality,
    required this.inSampleSize,
    required this.inputBytes,
    required this.outputBytesAvg,
    required this.latencyMsAvg,
    required this.latencyMsP95,
    required this.runs,
    this.error,
  });

  final String name;
  final BenchmarkMethod method;
  final CompressFormat format;
  final int quality;
  final int inSampleSize;
  final int inputBytes;
  final int outputBytesAvg;
  final int latencyMsAvg;
  final int latencyMsP95;
  final int runs;
  final String? error;

  bool get success => error == null;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'method': method.name,
      'format': format.name,
      'quality': quality,
      'inSampleSize': inSampleSize,
      'inputBytes': inputBytes,
      'outputBytesAvg': outputBytesAvg,
      'latencyMsAvg': latencyMsAvg,
      'latencyMsP95': latencyMsP95,
      'runs': runs,
      'error': error,
    };
  }
}

class BenchmarkRunResult {
  const BenchmarkRunResult({
    required this.startedAtMs,
    required this.totalElapsedMs,
    required this.warmupRuns,
    required this.measureRuns,
    required this.results,
    required this.groupedTotalMs,
    required this.concurrencyByFormat,
    required this.batchThroughputMatrix,
  });

  final int startedAtMs;
  final int totalElapsedMs;
  final int warmupRuns;
  final int measureRuns;
  final List<BenchmarkCaseResult> results;
  final Map<String, int> groupedTotalMs;
  final Map<String, BenchmarkConcurrencyResult> concurrencyByFormat;
  final List<BatchThroughputResult> batchThroughputMatrix;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'startedAtMs': startedAtMs,
      'totalElapsedMs': totalElapsedMs,
      'warmupRuns': warmupRuns,
      'measureRuns': measureRuns,
      'results': results.map((e) => e.toJson()).toList(),
      'groupedTotalMs': groupedTotalMs,
      'concurrencyByFormat': concurrencyByFormat.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'batchThroughputMatrix':
          batchThroughputMatrix.map((e) => e.toJson()).toList(),
    };
  }

  String toPrettyText() {
    final lines = <String>[
      'Benchmark finished.',
      'warmup=$warmupRuns, runs=$measureRuns',
    ];
    for (final item in results) {
      if (!item.success) {
        lines.add(
          '[FAIL] ${item.name} (${item.method.name}, ${item.format.name}) error=${item.error}',
        );
        continue;
      }
      final ratio =
          item.inputBytes == 0 ? 0.0 : item.outputBytesAvg / item.inputBytes;
      lines.add(
        '[OK] ${item.name} '
        'avg=${item.latencyMsAvg}ms '
        'p95=${item.latencyMsP95}ms '
        'size=${item.inputBytes}->${item.outputBytesAvg} '
        'ratio=${ratio.toStringAsFixed(3)}',
      );
    }
    for (final key in groupedTotalMs.keys.toList()..sort()) {
      lines.add('[GROUP] $key total=${groupedTotalMs[key]}ms');
    }
    lines.add('totalElapsedMs=$totalElapsedMs');
    for (final format in concurrencyByFormat.keys.toList()..sort()) {
      final concurrency = concurrencyByFormat[format]!;
      if (concurrency.success) {
        lines.add(
          '[CONCURRENCY] format=$format jobs=${concurrency.jobs} '
          'sequential=${concurrency.sequentialMs}ms '
          'parallel=${concurrency.parallelMs}ms '
          'speedup=${concurrency.speedup.toStringAsFixed(2)}x',
        );
      } else {
        lines.add(
          '[CONCURRENCY][FAIL] format=$format jobs=${concurrency.jobs} error=${concurrency.error}',
        );
      }
    }
    for (final row in batchThroughputMatrix) {
      lines.add(row.toPrettyLine());
    }
    return lines.join('\n');
  }
}

class BenchmarkConcurrencyResult {
  const BenchmarkConcurrencyResult({
    required this.jobs,
    required this.sequentialMs,
    required this.parallelMs,
    this.error,
  });

  final int jobs;
  final int sequentialMs;
  final int parallelMs;
  final String? error;

  bool get success => error == null;

  double get speedup {
    if (!success || parallelMs <= 0) {
      return 0.0;
    }
    return sequentialMs / parallelMs;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'jobs': jobs,
      'sequentialMs': sequentialMs,
      'parallelMs': parallelMs,
      'speedup': speedup,
      'error': error,
    };
  }
}

class BatchThroughputResult {
  const BatchThroughputResult({
    required this.format,
    required this.quality,
    required this.inSampleSize,
    required this.jobs,
    required this.concurrency,
    required this.totalElapsedMs,
    required this.p95CompletionMs,
    required this.successCount,
    required this.failureCount,
    this.error,
  });

  final CompressFormat format;
  final int quality;
  final int inSampleSize;
  final int jobs;
  final int concurrency;
  final int totalElapsedMs;
  final int p95CompletionMs;
  final int successCount;
  final int failureCount;
  final String? error;

  bool get success => error == null;

  double get throughputPerSec {
    if (totalElapsedMs <= 0) {
      return 0.0;
    }
    return successCount * 1000 / totalElapsedMs;
  }

  double get failureRate {
    if (jobs <= 0) {
      return 0.0;
    }
    return failureCount / jobs;
  }

  String toPrettyLine() {
    if (!success) {
      return '[BATCH][FAIL] format=${format.name} q$quality inSample=$inSampleSize '
          'concurrency=$concurrency n=$jobs error=$error';
    }
    return '[BATCH] format=${format.name} q$quality inSample=$inSampleSize '
        'concurrency=$concurrency n=$jobs total=${totalElapsedMs}ms '
        'throughput=${throughputPerSec.toStringAsFixed(2)}/s '
        'p95Done=${p95CompletionMs}ms '
        'failureRate=${(failureRate * 100).toStringAsFixed(2)}%';
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'format': format.name,
      'quality': quality,
      'inSampleSize': inSampleSize,
      'jobs': jobs,
      'concurrency': concurrency,
      'totalElapsedMs': totalElapsedMs,
      'throughputPerSec': throughputPerSec,
      'p95CompletionMs': p95CompletionMs,
      'successCount': successCount,
      'failureCount': failureCount,
      'failureRate': failureRate,
      'error': error,
    };
  }
}

class BenchmarkRunner {
  const BenchmarkRunner._();

  static const int defaultWarmupRuns = 2;
  static const int defaultMeasureRuns = 10;

  static List<BenchmarkCase> defaultCases() {
    return const <BenchmarkCase>[
      BenchmarkCase(
        name: 'list-jpeg-q75',
        method: BenchmarkMethod.compressWithList,
        format: CompressFormat.jpeg,
        quality: 75,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'list-webp-q75',
        method: BenchmarkMethod.compressWithList,
        format: CompressFormat.webp,
        quality: 75,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'file-jpeg-q75',
        method: BenchmarkMethod.compressWithFile,
        format: CompressFormat.jpeg,
        quality: 75,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'file-webp-q75',
        method: BenchmarkMethod.compressWithFile,
        format: CompressFormat.webp,
        quality: 75,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'tofile-jpeg-q75',
        method: BenchmarkMethod.compressAndGetFile,
        format: CompressFormat.jpeg,
        quality: 75,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'tofile-webp-q75',
        method: BenchmarkMethod.compressAndGetFile,
        format: CompressFormat.webp,
        quality: 75,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'list-jpeg-q70',
        method: BenchmarkMethod.compressWithList,
        format: CompressFormat.jpeg,
        quality: 70,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'list-webp-q70',
        method: BenchmarkMethod.compressWithList,
        format: CompressFormat.webp,
        quality: 70,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'file-jpeg-q70',
        method: BenchmarkMethod.compressWithFile,
        format: CompressFormat.jpeg,
        quality: 70,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'file-webp-q70',
        method: BenchmarkMethod.compressWithFile,
        format: CompressFormat.webp,
        quality: 70,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'tofile-jpeg-q70',
        method: BenchmarkMethod.compressAndGetFile,
        format: CompressFormat.jpeg,
        quality: 70,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
      BenchmarkCase(
        name: 'tofile-webp-q70',
        method: BenchmarkMethod.compressAndGetFile,
        format: CompressFormat.webp,
        quality: 70,
        inSampleSize: 2,
        minWidth: 1080,
        minHeight: 1080,
      ),
    ];
  }

  static Future<BenchmarkRunResult> run({
    required typed_data.Uint8List sourceBytes,
    required String sourcePath,
    required String temporaryDirectoryPath,
    List<BenchmarkCase>? cases,
    int warmupRuns = defaultWarmupRuns,
    int measureRuns = defaultMeasureRuns,
    int concurrencyJobs = 50,
    List<CompressFormat> concurrencyFormats = const <CompressFormat>[
      CompressFormat.jpeg,
      CompressFormat.webp,
    ],
    int concurrencyQuality = 75,
    int concurrencyInSampleSize = 2,
    int batchJobs = 50,
    List<CompressFormat> batchFormats = const <CompressFormat>[
      CompressFormat.jpeg,
      CompressFormat.webp,
    ],
    List<int> batchQualities = const <int>[70, 75],
    List<int> batchConcurrencyLevels = const <int>[1, 2, 4, 6, 8, 10],
    int batchInSampleSize = 2,
  }) async {
    final totalWatch = Stopwatch()..start();
    final useCases = cases ?? defaultCases();
    final startedAt = DateTime.now().millisecondsSinceEpoch;
    final results = <BenchmarkCaseResult>[];
    for (final benchCase in useCases) {
      results.add(
        await _runCase(
          benchCase,
          sourceBytes: sourceBytes,
          sourcePath: sourcePath,
          temporaryDirectoryPath: temporaryDirectoryPath,
          warmupRuns: warmupRuns,
          measureRuns: measureRuns,
        ),
      );
    }
    final concurrencyByFormat = <String, BenchmarkConcurrencyResult>{};
    for (final format in concurrencyFormats) {
      concurrencyByFormat[format.name] = await _runConcurrencyProbe(
        sourcePath: sourcePath,
        jobs: concurrencyJobs,
        format: format,
        quality: concurrencyQuality,
        inSampleSize: concurrencyInSampleSize,
      );
    }
    final groupedTotalMs = _buildGroupedTotals(results);
    final batchThroughputMatrix = <BatchThroughputResult>[];
    for (final format in batchFormats) {
      for (final quality in batchQualities) {
        for (final concurrency in batchConcurrencyLevels) {
          batchThroughputMatrix.add(
            await _runBatchThroughputProbe(
              sourcePath: sourcePath,
              format: format,
              quality: quality,
              inSampleSize: batchInSampleSize,
              jobs: batchJobs,
              concurrency: concurrency,
            ),
          );
        }
      }
    }
    totalWatch.stop();
    return BenchmarkRunResult(
      startedAtMs: startedAt,
      totalElapsedMs: totalWatch.elapsedMilliseconds,
      warmupRuns: warmupRuns,
      measureRuns: measureRuns,
      results: results,
      groupedTotalMs: groupedTotalMs,
      concurrencyByFormat: concurrencyByFormat,
      batchThroughputMatrix: batchThroughputMatrix,
    );
  }

  static Future<BenchmarkCaseResult> _runCase(
    BenchmarkCase benchCase, {
    required typed_data.Uint8List sourceBytes,
    required String sourcePath,
    required String temporaryDirectoryPath,
    required int warmupRuns,
    required int measureRuns,
  }) async {
    try {
      for (var i = 0; i < warmupRuns; i++) {
        await _runOnce(
          benchCase,
          sourceBytes: sourceBytes,
          sourcePath: sourcePath,
          temporaryDirectoryPath: temporaryDirectoryPath,
          runIndex: i,
        );
      }

      final latencies = <int>[];
      final outputSizes = <int>[];
      for (var i = 0; i < measureRuns; i++) {
        final watch = Stopwatch()..start();
        final outputSize = await _runOnce(
          benchCase,
          sourceBytes: sourceBytes,
          sourcePath: sourcePath,
          temporaryDirectoryPath: temporaryDirectoryPath,
          runIndex: i + warmupRuns,
        );
        watch.stop();
        latencies.add(watch.elapsedMilliseconds);
        outputSizes.add(outputSize);
      }

      return BenchmarkCaseResult(
        name: benchCase.name,
        method: benchCase.method,
        format: benchCase.format,
        quality: benchCase.quality,
        inSampleSize: benchCase.inSampleSize,
        inputBytes: sourceBytes.length,
        outputBytesAvg: _avgInt(outputSizes),
        latencyMsAvg: _avgInt(latencies),
        latencyMsP95: _p95(latencies),
        runs: measureRuns,
      );
    } catch (e) {
      return BenchmarkCaseResult(
        name: benchCase.name,
        method: benchCase.method,
        format: benchCase.format,
        quality: benchCase.quality,
        inSampleSize: benchCase.inSampleSize,
        inputBytes: sourceBytes.length,
        outputBytesAvg: 0,
        latencyMsAvg: 0,
        latencyMsP95: 0,
        runs: 0,
        error: e.toString(),
      );
    }
  }

  static Future<int> _runOnce(
    BenchmarkCase benchCase, {
    required typed_data.Uint8List sourceBytes,
    required String sourcePath,
    required String temporaryDirectoryPath,
    required int runIndex,
  }) async {
    switch (benchCase.method) {
      case BenchmarkMethod.compressWithList:
        final bytes = await ImageCompressPlus.compressWithList(
          sourceBytes,
          quality: benchCase.quality,
          inSampleSize: benchCase.inSampleSize,
          minWidth: benchCase.minWidth,
          minHeight: benchCase.minHeight,
          rotate: benchCase.rotate,
          format: benchCase.format,
        );
        return bytes.length;
      case BenchmarkMethod.compressWithFile:
        final bytes = await ImageCompressPlus.compressWithFile(
          sourcePath,
          quality: benchCase.quality,
          inSampleSize: benchCase.inSampleSize,
          minWidth: benchCase.minWidth,
          minHeight: benchCase.minHeight,
          rotate: benchCase.rotate,
          format: benchCase.format,
        );
        if (bytes == null) {
          throw StateError('compressWithFile returned null.');
        }
        return bytes.length;
      case BenchmarkMethod.compressAndGetFile:
        final outputPath = '$temporaryDirectoryPath/'
            '${benchCase.name}-${DateTime.now().millisecondsSinceEpoch}-$runIndex.'
            '${_extName(benchCase.format)}';
        final file = await ImageCompressPlus.compressAndGetFile(
          sourcePath,
          outputPath,
          quality: benchCase.quality,
          inSampleSize: benchCase.inSampleSize,
          minWidth: benchCase.minWidth,
          minHeight: benchCase.minHeight,
          rotate: benchCase.rotate,
          format: benchCase.format,
        );
        if (file == null) {
          throw StateError('compressAndGetFile returned null.');
        }
        return await file.length();
    }
  }

  static String _extName(CompressFormat format) {
    switch (format) {
      case CompressFormat.jpeg:
        return 'jpg';
      case CompressFormat.png:
        return 'png';
      case CompressFormat.heic:
        return 'heic';
      case CompressFormat.webp:
        return 'webp';
    }
  }

  static Future<BenchmarkConcurrencyResult> _runConcurrencyProbe({
    required String sourcePath,
    required int jobs,
    required CompressFormat format,
    required int quality,
    required int inSampleSize,
  }) async {
    try {
      final singleTask = () async {
        final result = await ImageCompressPlus.compressWithFile(
          sourcePath,
          quality: quality,
          inSampleSize: inSampleSize,
          minWidth: 1080,
          minHeight: 1080,
          rotate: 0,
          format: format,
        );
        if (result == null) {
          throw StateError('concurrency probe returned null.');
        }
      };

      final sequentialWatch = Stopwatch()..start();
      for (var i = 0; i < jobs; i++) {
        await singleTask();
      }
      sequentialWatch.stop();

      final parallelWatch = Stopwatch()..start();
      await Future.wait(
        List<Future<void>>.generate(jobs, (_) => singleTask()),
      );
      parallelWatch.stop();

      return BenchmarkConcurrencyResult(
        jobs: jobs,
        sequentialMs: sequentialWatch.elapsedMilliseconds,
        parallelMs: parallelWatch.elapsedMilliseconds,
      );
    } catch (e) {
      return BenchmarkConcurrencyResult(
        jobs: jobs,
        sequentialMs: 0,
        parallelMs: 0,
        error: e.toString(),
      );
    }
  }

  static int _avgInt(List<int> values) {
    if (values.isEmpty) {
      return 0;
    }
    final total = values.reduce((a, b) => a + b);
    return (total / values.length).round();
  }

  static int _p95(List<int> values) {
    if (values.isEmpty) {
      return 0;
    }
    final sorted = List<int>.from(values)..sort();
    final index = ((sorted.length - 1) * 0.95).ceil();
    return sorted[index];
  }

  static Future<BatchThroughputResult> _runBatchThroughputProbe({
    required String sourcePath,
    required CompressFormat format,
    required int quality,
    required int inSampleSize,
    required int jobs,
    required int concurrency,
  }) async {
    try {
      var nextIndex = 0;
      var failureCount = 0;
      final successCompletionMs = <int>[];
      final watch = Stopwatch()..start();

      Future<void> runWorker() async {
        while (true) {
          if (nextIndex >= jobs) {
            return;
          }
          nextIndex += 1;
          try {
            final result = await ImageCompressPlus.compressWithFile(
              sourcePath,
              quality: quality,
              inSampleSize: inSampleSize,
              minWidth: 1080,
              minHeight: 1080,
              rotate: 0,
              format: format,
            );
            if (result == null) {
              failureCount += 1;
            } else {
              successCompletionMs.add(watch.elapsedMilliseconds);
            }
          } catch (_) {
            failureCount += 1;
          }
        }
      }

      final workers = <Future<void>>[];
      final workerCount = concurrency < 1 ? 1 : concurrency;
      for (var i = 0; i < workerCount; i++) {
        workers.add(runWorker());
      }
      await Future.wait(workers);
      watch.stop();

      final p95Done = _p95(successCompletionMs);
      final successCount = jobs - failureCount;
      return BatchThroughputResult(
        format: format,
        quality: quality,
        inSampleSize: inSampleSize,
        jobs: jobs,
        concurrency: workerCount,
        totalElapsedMs: watch.elapsedMilliseconds,
        p95CompletionMs: p95Done,
        successCount: successCount,
        failureCount: failureCount,
      );
    } catch (e) {
      return BatchThroughputResult(
        format: format,
        quality: quality,
        inSampleSize: inSampleSize,
        jobs: jobs,
        concurrency: concurrency,
        totalElapsedMs: 0,
        p95CompletionMs: 0,
        successCount: 0,
        failureCount: jobs,
        error: e.toString(),
      );
    }
  }

  static Map<String, int> _buildGroupedTotals(
      List<BenchmarkCaseResult> results) {
    final grouped = <String, int>{};
    for (final item in results) {
      if (!item.success) {
        continue;
      }
      final key = '${item.format.name}-q${item.quality}';
      final totalMs = item.latencyMsAvg * item.runs;
      grouped[key] = (grouped[key] ?? 0) + totalMs;
    }
    return grouped;
  }
}
