import Flutter
import SDWebImageWebPCoder
import UIKit

@objc(ImageCompressPlugin)
public class ImageCompressPlugin: NSObject, FlutterPlugin, ImageCompressPlusHostApi {
  private static let stateLock = NSLock()
  private static var showLogEnabled = false
  private static var hasRegisteredWebPCoder = false
  private static let workQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.qualityOfService = .userInitiated
    let cpuCount = ProcessInfo.processInfo.activeProcessorCount
    queue.maxConcurrentOperationCount = max(1, min(cpuCount, 3))
    return queue
  }()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let instance = ImageCompressPlugin()
    ImageCompressPlusHostApiSetup.setUp(binaryMessenger: registrar.messenger(), api: instance)

    stateLock.lock()
    defer { stateLock.unlock() }
    if !hasRegisteredWebPCoder {
      SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
      hasRegisteredWebPCoder = true
    }
  }

  private func executeOnWorkQueue(_ work: @escaping () -> Void) {
    ImageCompressPlugin.workQueue.addOperation {
      autoreleasepool {
        work()
      }
    }
  }

  private func setShowLogEnabled(_ enabled: Bool) {
    ImageCompressPlugin.stateLock.lock()
    ImageCompressPlugin.showLogEnabled = enabled
    ImageCompressPlugin.stateLock.unlock()
  }

  private func completeOnMain<T>(
    _ completion: @escaping (Result<T, Error>) -> Void,
    with result: Result<T, Error>
  ) {
    DispatchQueue.main.async {
      completion(result)
    }
  }

  private func makeRequest(
    targetWidth: Int64,
    targetHeight: Int64,
    quality: Int64,
    rotate: Int64,
    autoCorrectionAngle: Bool,
    targetFormat: HostFormat,
    keepExif: Bool
  ) -> CompressionRequest {
    CompressionRequest(
      targetWidth: Int(targetWidth),
      targetHeight: Int(targetHeight),
      quality: Int(quality),
      rotate: Int(rotate),
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: targetFormat,
      keepExif: keepExif,
      logEnabled: ImageCompressPlugin.showLog()
    )
  }

  private func runRetriableFileOperation<T>(
    numberOfRetries: Int64,
    logEnabled: Bool,
    work: () throws -> T
  ) throws -> T {
    let attempts = max(1, Int(numberOfRetries))
    var lastError: Error?

    for attempt in 1...attempts {
      do {
        return try work()
      } catch {
        if !shouldRetry(after: error) {
          throw error
        }
        lastError = error
      }

      if attempt < attempts, logEnabled {
        NSLog("Retrying image compression, attempt %d of %d", attempt + 1, attempts)
      }
    }

    if let lastError {
      throw lastError
    }

    throw PigeonError(
      code: "compress_failed",
      message: "Failed to compress image file.",
      details: nil
    )
  }

  private func compressImageData(_ data: Data, request: CompressionRequest) throws -> Data {
    try ImageCompressor.compress(data, request: request)
  }

  private func compressImageFile(path: String, request: CompressionRequest) throws -> Data {
    do {
      let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
      return try compressImageData(data, request: request)
    } catch {
      throw wrapFileSystemError(
        error,
        path: path,
        transientCode: "transient_file_read_failed",
        stableCode: "file_read_failed",
        message: "Failed to read image file."
      )
    }
  }

  private func compressImageFileToTarget(
    path: String,
    targetPath: String,
    request: CompressionRequest
  ) throws -> String {
    let compressedData = try compressImageFile(path: path, request: request)
    do {
      try compressedData.write(to: URL(fileURLWithPath: targetPath), options: .atomic)
      return targetPath
    } catch {
      throw wrapFileSystemError(
        error,
        path: targetPath,
        transientCode: "transient_file_write_failed",
        stableCode: "file_write_failed",
        message: "Failed to write compressed image file."
      )
    }
  }

  public func compressWithList(
    image: FlutterStandardTypedData,
    targetWidth: Int64,
    targetHeight: Int64,
    quality: Int64,
    rotate: Int64,
    autoCorrectionAngle: Bool,
    targetFormat: HostFormat,
    keepExif: Bool,
    completion: @escaping (Result<FlutterStandardTypedData, Error>) -> Void
  ) {

    let request = makeRequest(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: targetFormat,
      keepExif: keepExif
    )

    executeOnWorkQueue {
      do {
        let data = try self.compressImageData(image.data, request: request)
        self.completeOnMain(completion, with: .success(FlutterStandardTypedData(bytes: data)))
      } catch {
        self.completeOnMain(completion, with: .failure(error))
      }
    }
  }

  public func compressWithFile(
    path: String,
    targetWidth: Int64,
    targetHeight: Int64,
    quality: Int64,
    rotate: Int64,
    autoCorrectionAngle: Bool,
    targetFormat: HostFormat,
    keepExif: Bool,
    numberOfRetries: Int64,
    completion: @escaping (Result<FlutterStandardTypedData?, Error>) -> Void
  ) {

    let request = makeRequest(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: targetFormat,
      keepExif: keepExif
    )

    executeOnWorkQueue {
      do {
        let data = try self.runRetriableFileOperation(
          numberOfRetries: numberOfRetries,
          logEnabled: request.logEnabled
        ) {
          try self.compressImageFile(path: path, request: request)
        }
        self.completeOnMain(
          completion,
          with: .success(FlutterStandardTypedData(bytes: data) as FlutterStandardTypedData?)
        )
      } catch {
        self.completeOnMain(completion, with: .failure(error))
      }
    }
  }

  public func compressWithFileAndGetFile(
    path: String,
    targetWidth: Int64,
    targetHeight: Int64,
    quality: Int64,
    targetPath: String,
    rotate: Int64,
    autoCorrectionAngle: Bool,
    targetFormat: HostFormat,
    keepExif: Bool,
    numberOfRetries: Int64,
    completion: @escaping (Result<String?, Error>) -> Void
  ) {

    let request = makeRequest(
      targetWidth: targetWidth,
      targetHeight: targetHeight,
      quality: quality,
      rotate: rotate,
      autoCorrectionAngle: autoCorrectionAngle,
      targetFormat: targetFormat,
      keepExif: keepExif
    )

    executeOnWorkQueue {
      do {
        let result = try self.runRetriableFileOperation(
          numberOfRetries: numberOfRetries,
          logEnabled: request.logEnabled
        ) {
          try self.compressImageFileToTarget(path: path, targetPath: targetPath, request: request)
        }
        self.completeOnMain(completion, with: .success(result as String?))
      } catch {
        self.completeOnMain(completion, with: .failure(error))
      }
    }
  }

  public func showLog(value: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
    setShowLogEnabled(value)
    completeOnMain(completion, with: .success(()))
  }

  static func showLog() -> Bool {
    stateLock.lock()
    defer { stateLock.unlock() }
    return showLogEnabled
  }

  private func shouldRetry(after error: Error) -> Bool {
    if let error = error as? PigeonError {
      return error.code == "transient_file_read_failed"
        || error.code == "transient_file_write_failed"
    }
    return false
  }

  private func wrapFileSystemError(
    _ error: Error,
    path: String,
    transientCode: String,
    stableCode: String,
    message: String
  ) -> PigeonError {
    let nsError = error as NSError
    let code = isTransientFileSystemError(nsError) ? transientCode : stableCode
    return PigeonError(
      code: code,
      message: message,
      details: "path=\(path), domain=\(nsError.domain), code=\(nsError.code)"
    )
  }

  private func isTransientFileSystemError(_ error: NSError) -> Bool {
    if error.domain == NSPOSIXErrorDomain {
      return [EAGAIN, EBUSY, EINTR, ETIMEDOUT].contains(error.code)
    }

    if error.domain == NSCocoaErrorDomain {
      return [
        NSFileReadUnknownError,
        NSFileWriteUnknownError
      ].contains(error.code)
    }

    return false
  }
}
