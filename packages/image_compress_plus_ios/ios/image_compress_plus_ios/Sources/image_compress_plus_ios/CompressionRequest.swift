import Foundation

struct CompressionRequest {
  let targetWidth: Int
  let targetHeight: Int
  let quality: Int
  let rotate: Int
  let autoCorrectionAngle: Bool
  let targetFormat: HostFormat
  let keepExif: Bool
  let logEnabled: Bool
}
