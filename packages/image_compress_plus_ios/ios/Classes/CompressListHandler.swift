import Foundation
import Flutter

final class CompressListHandler {
  func handle(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [Any], args.count >= 8 else {
      result(nil)
      return
    }

    guard let list = args[0] as? FlutterStandardTypedData else {
      result(nil)
      return
    }

    let minWidth = (args[1] as? NSNumber)?.intValue ?? 0
    let minHeight = (args[2] as? NSNumber)?.intValue ?? 0
    let quality = (args[3] as? NSNumber)?.intValue ?? 0
    let rotate = (args[4] as? NSNumber)?.intValue ?? 0
    let formatType = (args[6] as? NSNumber)?.intValue ?? 0
    let keepExif = (args[7] as? NSNumber)?.boolValue ?? false

    let data = list.data
    guard var compressedData = CompressHandler.compressWithData(
      data,
      minWidth: minWidth,
      minHeight: minHeight,
      quality: quality,
      rotate: rotate,
      format: formatType
    ) else {
      result(nil)
      return
    }

    if keepExif, let updated = CompressHandler.attachMetadata(originalData: data, compressedData: compressedData) {
      compressedData = updated
    }

    result(FlutterStandardTypedData(bytes: compressedData))
  }
}
