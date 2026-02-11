import Cocoa
import FlutterMacOS
import AVFoundation

class Logger {

  static var isShowLog = false

  static func showLog(show: Bool) {
    isShowLog = show
  }

  static func log(msg: String) {
    if (!isShowLog) {
      return
    }
    NSLog("\(msg)")
  }

  static func logFile(path: String) {
    if (!isShowLog) {
      return
    }
    let url = URL(fileURLWithPath: path)
    NSLog("The file: \(url)")
  }

  static func logData(data: Data) {
    if (!isShowLog) {
      return
    }
    if data.count < 2 {
      NSLog("The data is empty or too short, length: \(data.count)")
      return
    }
    NSLog("The data: \(data), length: \(data.count)")

    // check data type, maybe jpeg png or heic
    let isJpeg = data[0] == 0xFF && data[1] == 0xD8
    let isPng = data[0] == 0x89 && data[1] == 0x50

    let heicHeader = "ftypheic"
    let isHeic = data.count > heicHeader.count && String(data: data.subdata(in: 4..<heicHeader.count + 4), encoding: .utf8) == heicHeader

    let outputFormat = isJpeg ? "jpg" : (isPng ? "png" : (isHeic ? "heic" : "unknown"))

    // write data to file
    let url = URL(fileURLWithPath: "\(NSTemporaryDirectory())/\(Date().timeIntervalSince1970).\(outputFormat)")
    do {
      try data.write(to: url)
      NSLog("The file: \(url)")
    } catch {
      NSLog("Write file error: \(error)")
    }
  }
}

class ImageSrc {
  let source: CGImageSource
  let metadata: Dictionary<CFString, Any>

  init(source: CGImageSource, metadata: Dictionary<CFString, Any>) {
    self.source = source
    self.metadata = metadata
  }

}

public class FlutterImageCompressMacosPlugin: NSObject, FlutterPlugin {
  private static let workQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.qualityOfService = .userInitiated
    let cpuCount = ProcessInfo.processInfo.activeProcessorCount
    queue.maxConcurrentOperationCount = max(2, min(cpuCount, 6))
    return queue
  }()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_compress_plus", binaryMessenger: registrar.messenger)
    let instance = FlutterImageCompressMacosPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)
  }

  func makeImageSrc(source: CGImageSource, params: Dictionary<String, Any>) -> ImageSrc {
    let keepExif = (params["keepExif"] as? Bool) ?? false

    var metadata = Dictionary<CFString, Any>()
    if (keepExif) {
      if let imageProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any] {
        let reservedKeys: [CFString] = [
          kCGImagePropertyExifDictionary,
          kCGImagePropertyJFIFDictionary,
          kCGImagePropertyTIFFDictionary,
          kCGImagePropertyPNGDictionary,
          kCGImagePropertyGPSDictionary,
          kCGImagePropertyIPTCDictionary
        ]
        for key in reservedKeys {
          if let value = imageProperties[key] {
            metadata[key] = value
          }
        }
      }
    }

    return ImageSrc(source: source, metadata: metadata)
  }

  func makeFlutterError(code: String = "The incoming parameters do not contain image.") -> FlutterError {
    FlutterError(code: code, message: nil, details: nil)
  }

  func handleResult(_ args: Any?) -> Compressor? {
    guard let params = args as? Dictionary<String, Any> else {
      return nil
    }

    if params["list"] != nil {
      guard let data = params["list"] as? FlutterStandardTypedData else {
        return nil
      }
      let nsData = data.data

      guard let source = CGImageSourceCreateWithData(nsData as CFData, nil)
      else {
        return nil
      }
      let image = makeImageSrc(source: source, params: params)
      return Compressor(image: image, params: params)
    }

    if params["path"] != nil {
      guard let path = params["path"] as? String else {
        return nil
      }
      guard let source = CGImageSourceCreateWithURL(URL(fileURLWithPath: path) as CFURL, nil)
      else {
        return nil
      }

      let image = makeImageSrc(source: source, params: params)
      return Compressor(image: image, params: params)
    }

    return nil
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    let method = call.method
    let args = call.arguments

    switch method {
    case "showLog":
      Logger.showLog(show: args as! Bool)
      result(1)
      return
    case "compressAndGetFile":
      guard let parsed = args as? Dictionary<String, Any>,
            let dstPath = parsed["targetPath"] as? String,
            let compressor = handleResult(args) else {
        result(makeFlutterError())
        return
      }
      Self.workQueue.addOperation {
        compressor.compressToPath({ value in
          OperationQueue.main.addOperation {
            result(value)
          }
        }, dstPath)
      }
      break
    case "compressWithFile":
      guard let compressor = handleResult(args) else {
        result(makeFlutterError())
        return
      }
      Self.workQueue.addOperation {
        compressor.compressToBytes { value in
          OperationQueue.main.addOperation {
            result(value)
          }
        }
      }
      break
    case "compressWithList":
      guard let compressor = handleResult(args) else {
        result(makeFlutterError())
        return
      }
      Self.workQueue.addOperation {
        compressor.compressToBytes { value in
          OperationQueue.main.addOperation {
            result(value)
          }
        }
      }
      break
    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

class Compressor {

  let image: ImageSrc
  let params: Dictionary<String, Any>

  init(image: ImageSrc, params: Dictionary<String, Any>) {
    self.image = image
    self.params = params
  }

  func getOutputFormat() -> CFString {
    let format = (params["format"] as? Int) ?? 0

    switch (format) {
    case 0:
      return kUTTypeJPEG
    case 1:
      return kUTTypePNG
    case 2:
      return AVFileType.heic as CFString
    default:
      return kUTTypeJPEG
    }
  }


  /**
   处理图片
   - Parameters:
     - image: 源图片
     - angle: 角度
     - targetSize: 目标图片的尺寸
     - dest: 目标图片
   */
  private func encodeFromSource(dest: CGImageDestination) -> Bool {
    let options = makeOptions()
    CGImageDestinationAddImageFromSource(dest, image.source, 0, options)
    return CGImageDestinationFinalize(dest)
  }

  func handleImage(srcCGImage: CGImage, angle: Int, dest: CGImageDestination) -> Bool {
    let options = makeOptions()
    if angle % 360 == 0 {
      CGImageDestinationAddImage(dest, srcCGImage, options)
      return CGImageDestinationFinalize(dest)
    }

    let radian = CGFloat(angle) * CGFloat.pi / 180
    let affine = CGAffineTransform(rotationAngle: radian)
    let width = srcCGImage.width
    let height = srcCGImage.height
    let srcRect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
    let rotatedRect = srcRect.applying(affine)
    let rotatedSize = CGSize(width: ceil(abs(rotatedRect.width)),
                             height: ceil(abs(rotatedRect.height)))

    guard let cgContext = CGContext(
      data: nil,
      width: Int(rotatedSize.width),
      height: Int(rotatedSize.height),
      bitsPerComponent: 8,
      bytesPerRow: 0,
      space: CGColorSpaceCreateDeviceRGB(),
      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
      return false
    }

    cgContext.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
    cgContext.rotate(by: radian)
    cgContext.draw(srcCGImage, in: CGRect(x: -width / 2, y: -height / 2, width: width, height: height))

    guard let rotatedImage = cgContext.makeImage() else {
      return false
    }
    CGImageDestinationAddImage(dest, rotatedImage, options)
    return CGImageDestinationFinalize(dest)
  }

  private func sourcePixelSize() -> CGSize {
    guard let properties = CGImageSourceCopyPropertiesAtIndex(image.source, 0, nil) as? [CFString: Any],
          let width = properties[kCGImagePropertyPixelWidth] as? CGFloat,
          let height = properties[kCGImagePropertyPixelHeight] as? CGFloat else {
      return .zero
    }
    return CGSize(width: width, height: height)
  }

  private func makeSourceImage(targetSize: CGSize, srcSize: CGSize) -> CGImage? {
    let maxPixelSize = max(targetSize.width, targetSize.height)
    if maxPixelSize > 0, maxPixelSize < max(srcSize.width, srcSize.height) {
      let options: [CFString: Any] = [
        kCGImageSourceCreateThumbnailFromImageAlways: true,
        kCGImageSourceThumbnailMaxPixelSize: Int(ceil(maxPixelSize)),
        kCGImageSourceCreateThumbnailWithTransform: false
      ]
      return CGImageSourceCreateThumbnailAtIndex(image.source, 0, options as CFDictionary)
    }
    return CGImageSourceCreateImageAtIndex(image.source, 0, nil)
  }

  private func makeOptions() -> CFDictionary {
    let dict = NSMutableDictionary()

    let quality = (params["quality"] as? Int) ?? 95
    let qualityValue = CGFloat(quality) / 100.0

    let keepExif = (params["keepExif"] as? Bool) ?? false

    if (keepExif) {
      // remove orientation
      dict[kCGImagePropertyOrientation] = 1

      for param in image.metadata {
        dict[param.key] = param.value
      }
    }

    dict[kCGImageDestinationLossyCompressionQuality] = qualityValue

    return dict as CFDictionary
  }

  func compress(destCreator: () -> CGImageDestination?) -> FlutterError? {
    let minWidth = CGFloat((params["minWidth"] as? Int) ?? 1920)
    let minHeight = CGFloat((params["minHeight"] as? Int) ?? 1080)
    let inSampleSize = max(1, (params["inSampleSize"] as? Int) ?? 1)
    let srcSize = sourcePixelSize()
    guard srcSize.width > 0, srcSize.height > 0 else {
      return FlutterError(code: "invalid_source", message: "Invalid source image size.", details: nil)
    }
    let srcWidth = srcSize.width
    let srcHeight = srcSize.height

    let srcRatio = srcWidth / srcHeight
    let maxRatio = minWidth / minHeight
    var scaleRatio = 1.0

    if srcRatio < maxRatio {
      scaleRatio = minWidth / srcWidth
    } else {
      scaleRatio = minHeight / srcHeight
    }

    scaleRatio = min(scaleRatio, 1.0)

    let targetWidth = max(1, floor((srcWidth * scaleRatio) / CGFloat(inSampleSize)))
    let targetHeight = max(1, floor((srcHeight * scaleRatio) / CGFloat(inSampleSize)))

    guard let dest = destCreator() else {
      return FlutterError(code: "create_destination_failed", message: "Failed to create destination image.", details: nil)
    }
    let angle = (params["rotate"] as? Int) ?? 0

    // Fast path for JPEG: no resize and no rotate, directly transcode from source.
    if getOutputFormat() == kUTTypeJPEG, angle % 360 == 0, scaleRatio >= 0.9999, inSampleSize == 1 {
      if !encodeFromSource(dest: dest) {
        return FlutterError(code: "encode_error", message: "Failed to encode destination image.", details: nil)
      }
      return nil
    }

    let targetSize = CGSize(width: targetWidth, height: targetHeight)
    guard let srcCGImage = makeSourceImage(targetSize: targetSize, srcSize: srcSize) else {
      return FlutterError(code: "decode_error", message: "Failed to decode source image.", details: nil)
    }

    if !handleImage(srcCGImage: srcCGImage, angle: angle, dest: dest) {
      return FlutterError(code: "encode_error", message: "Failed to encode destination image.", details: nil)
    }
    return nil
  }

  func compressToPath(_ result: @escaping (Any?) -> (), _ path: String) {
    let url = URL(fileURLWithPath: path)
    var error: FlutterError?
    autoreleasepool {
      error = compress {
        CGImageDestinationCreateWithURL(url as CFURL, getOutputFormat(), 1, nil)
      }
    }
    if let error {
      result(error)
      return
    }

    Logger.logFile(path: path)
    result(path)
  }

  func compressToBytes(_ result: @escaping (Any?) -> ()) {
    let data = NSMutableData()
    var error: FlutterError?
    autoreleasepool {
      error = compress {
        CGImageDestinationCreateWithData(data, getOutputFormat(), 1, nil)
      }
    }
    if let error {
      result(error)
      return
    }

    Logger.logData(data: data as Data)
    result(FlutterStandardTypedData(bytes: data as Data))
  }

}

enum CompressFormat {
  case jpeg
  case png
  case heic
  case webp

  static func convertInt(type: Int) -> CompressFormat {
    switch (type) {
    case 0:
      return .jpeg
    case 1:
      return .png
    case 2:
      return .heic
    case 3:
      return .webp
    default:
      return .jpeg
    }
  }
}
