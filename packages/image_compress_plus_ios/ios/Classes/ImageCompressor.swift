import Foundation
import UIKit
import ImageIO

enum ImageCompressor {
  static func compress(_ data: Data, request: CompressionRequest) throws -> Data {
    let decodingContext = try makeDecodingContext(for: data)
    let compressedData = compressImage(data, decodingContext: decodingContext, request: request)

    guard let compressedData else {
      throw PigeonError(
        code: "compress_failed",
        message: "Failed to compress input image.",
        details: decodingContext.typeIdentifier
      )
    }

    return compressedData
  }

  private struct DecodingContext {
    let source: CGImageSource
    let typeIdentifier: String?
    let useWebPFallback: Bool
  }

  private static func compressImage(
    _ data: Data,
    decodingContext: DecodingContext,
    request: CompressionRequest
  ) -> Data? {
    let orientation = CompressionSupport.cgImageOrientation(for: data)
    let adjustedSize = CompressionSupport.correctedTargetSize(
      for: orientation,
      targetWidth: request.targetWidth,
      targetHeight: request.targetHeight,
      autoCorrectionAngle: request.autoCorrectionAngle
    )

    let decodedImage: UIImage?
    if decodingContext.useWebPFallback {
      decodedImage = CompressionSupport.decodeWebPImage(
        data,
        targetWidth: adjustedSize.width,
        targetHeight: adjustedSize.height,
        applyTransform: request.autoCorrectionAngle
      )
    } else {
      decodedImage = CompressionSupport.decodeImage(
        source: decodingContext.source,
        targetWidth: adjustedSize.width,
        targetHeight: adjustedSize.height,
        applyTransform: request.autoCorrectionAngle
      )
    }

    guard let image = decodedImage else {
      return nil
    }

    if request.logEnabled {
      let sourcePixels = image.compressionPixelSize
      NSLog("width = %.0f", sourcePixels.width)
      NSLog("height = %.0f", sourcePixels.height)
      NSLog("targetWidth = %d", adjustedSize.width)
      NSLog("targetHeight = %d", adjustedSize.height)
      NSLog("targetFormat = %d", request.targetFormat.rawValue)
    }

    let processedImage = image.renderedForCompression(
      maxPixelWidth: adjustedSize.width,
      maxPixelHeight: adjustedSize.height,
      rotateDegrees: CGFloat(request.rotate),
      logEnabled: request.logEnabled
    )

    return finalize(image: processedImage, originalData: data, request: request)
  }

  private static func finalize(
    image: UIImage,
    originalData: Data,
    request: CompressionRequest
  ) -> Data? {
    guard var compressedData = CompressionSupport.encode(
      image: image,
      targetFormat: request.targetFormat,
      quality: request.quality
    ) else {
      return nil
    }

    if request.keepExif,
       let updated = CompressionSupport.attachMetadata(
         originalData: originalData,
         compressedData: compressedData,
         preserveOriginalOrientation: !request.autoCorrectionAngle && request.rotate % 360 == 0
       ) {
      compressedData = updated
    }

    return compressedData
  }

  private static func makeDecodingContext(for data: Data) throws -> DecodingContext {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
      throw unsupportedInputFormatError(details: "unrecognized")
    }

    let typeIdentifier = CGImageSourceGetType(source) as String?
    if isLikelyWebP(data, typeIdentifier: typeIdentifier) {
      return DecodingContext(
        source: source,
        typeIdentifier: typeIdentifier,
        useWebPFallback: true
      )
    }

    let canDecodeWithImageIO =
      CGImageSourceCopyPropertiesAtIndex(source, 0, nil) != nil
      || CGImageSourceCreateImageAtIndex(source, 0, nil) != nil

    if canDecodeWithImageIO {
      return DecodingContext(
        source: source,
        typeIdentifier: typeIdentifier,
        useWebPFallback: false
      )
    }

    // Accept as many input formats as the runtime can decode with ImageIO.
    // Only fall back to a dedicated coder when we can positively identify a
    // format we explicitly support outside ImageIO.
    throw unsupportedInputFormatError(details: typeIdentifier ?? "unparseable")
  }

  private static func unsupportedInputFormatError(details: Any? = nil) -> PigeonError {
    PigeonError(
      code: "unsupported_input_format",
      message: "Unsupported input image format.",
      details: details
    )
  }

  private static func isLikelyWebP(_ data: Data, typeIdentifier: String?) -> Bool {
    if let typeIdentifier,
       typeIdentifier == "public.webp" || typeIdentifier == "org.webmproject.webp" {
      return true
    }

    guard data.count >= 12 else {
      return false
    }
    let riff = String(data: data.subdata(in: 0..<4), encoding: .ascii)
    let webp = String(data: data.subdata(in: 8..<12), encoding: .ascii)
    return riff == "RIFF" && webp == "WEBP"
  }
}
