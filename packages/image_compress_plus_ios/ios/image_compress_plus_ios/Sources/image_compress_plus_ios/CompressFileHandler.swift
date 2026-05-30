import Foundation
import Flutter

final class CompressFileHandler {
  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [Any], args.count >= 9 else {
      result(nil)
      return
    }

    let path = args[0] as? String ?? ""
    let minWidth = (args[1] as? NSNumber)?.intValue ?? 0
    let minHeight = (args[2] as? NSNumber)?.intValue ?? 0
    let quality = (args[3] as? NSNumber)?.intValue ?? 0
    let rotate = (args[4] as? NSNumber)?.intValue ?? 0
    let formatType = (args[6] as? NSNumber)?.intValue ?? 0
    let keepExif = (args[7] as? NSNumber)?.boolValue ?? false
    let inSampleSize = (args[8] as? NSNumber)?.intValue ?? 1

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
      result(nil)
      return
    }

    autoreleasepool {
      var compressedData = CompressHandler.compressWithData(
        data,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        rotate: rotate,
        format: formatType,
        inSampleSize: inSampleSize
      )

      if keepExif, let output = compressedData,
         let updated = CompressHandler.attachMetadata(originalData: data, compressedData: output) {
        compressedData = updated
      }

      if let output = compressedData {
        result(FlutterStandardTypedData(bytes: output))
      } else {
        result(nil)
      }
    }
  }

  func handleCompressFileToFile(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [Any], args.count >= 10 else {
      result(nil)
      return
    }

    let path = args[0] as? String ?? ""
    let minWidth = (args[1] as? NSNumber)?.intValue ?? 0
    let minHeight = (args[2] as? NSNumber)?.intValue ?? 0
    let quality = (args[3] as? NSNumber)?.intValue ?? 0
    let targetPath = args[4] as? String ?? ""
    let rotate = (args[5] as? NSNumber)?.intValue ?? 0
    let formatType = (args[7] as? NSNumber)?.intValue ?? 0
    let keepExif = (args[8] as? NSNumber)?.boolValue ?? false
    let inSampleSize = (args[9] as? NSNumber)?.intValue ?? 1

    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe) else {
      result(nil)
      return
    }

    autoreleasepool {
      var compressedData = CompressHandler.compressWithData(
        data,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        rotate: rotate,
        format: formatType,
        inSampleSize: inSampleSize
      )

      if keepExif, let output = compressedData,
         let updated = CompressHandler.attachMetadata(originalData: data, compressedData: output) {
        compressedData = updated
      }

      if let output = compressedData {
        try? output.write(to: URL(fileURLWithPath: targetPath), options: .atomic)
        result(targetPath)
      } else {
        result(nil)
      }
    }
  }

}
