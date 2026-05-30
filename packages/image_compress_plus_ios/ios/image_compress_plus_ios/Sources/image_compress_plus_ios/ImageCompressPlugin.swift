import Flutter
import UIKit
import SDWebImageWebPCoder

@objc(ImageCompressPlugin)
public class ImageCompressPlugin: NSObject, FlutterPlugin {
  private static var showLogEnabled = false
  private static let workQueue: OperationQueue = {
    let queue = OperationQueue()
    queue.qualityOfService = .userInitiated
    let cpuCount = ProcessInfo.processInfo.activeProcessorCount
    queue.maxConcurrentOperationCount = max(4, min(cpuCount, 6))
    return queue
  }()

  public static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(name: "image_compress_plus", binaryMessenger: registrar.messenger())
    let instance = ImageCompressPlugin()
    registrar.addMethodCallDelegate(instance, channel: channel)

    // Register WebP coder once.
    SDImageCodersManager.shared.addCoder(SDImageWebPCoder.shared)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    ImageCompressPlugin.workQueue.addOperation {
      switch call.method {
      case "compressWithList":
        CompressListHandler().handle(call: call, result: result)
      case "compressWithFile":
        CompressFileHandler().handle(call: call, result: result)
      case "compressWithFileAndGetFile":
        CompressFileHandler().handleCompressFileToFile(call: call, result: result)
      case "showLog":
        if let flag = call.arguments as? NSNumber {
          ImageCompressPlugin.showLogEnabled = flag.boolValue
        } else if let flag = call.arguments as? Bool {
          ImageCompressPlugin.showLogEnabled = flag
        }
        result(1)
      case "getSystemVersion":
        result(UIDevice.current.systemVersion)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  static func showLog() -> Bool {
    return showLogEnabled
  }
}
