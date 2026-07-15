import Foundation
import UIKit
import ImageIO
import CoreImage
import SDWebImageWebPCoder

enum CompressionSupport {
  static func imageOrientation(for data: Data) -> UIImage.Orientation {
    switch cgImageOrientation(for: data) {
    case .up:
      return .up
    case .upMirrored:
      return .upMirrored
    case .down:
      return .down
    case .downMirrored:
      return .downMirrored
    case .left:
      return .left
    case .leftMirrored:
      return .leftMirrored
    case .right:
      return .right
    case .rightMirrored:
      return .rightMirrored
    default:
      return .up
    }
  }

  static func encode(image: UIImage, targetFormat: HostFormat, quality: Int) -> Data? {
    if targetFormat == .heic {
      guard #available(iOS 11.0, *) else {
        return nil
      }
      guard let cgImage = cgImage(for: image) else {
        return nil
      }
      let data = NSMutableData()
      let heicType = "public.heic" as CFString
      guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, heicType, 1, nil) else {
        return nil
      }
      let options = [kCGImageDestinationLossyCompressionQuality: Float(quality) / 100.0] as CFDictionary
      CGImageDestinationAddImage(destination, cgImage, options)
      guard CGImageDestinationFinalize(destination) else {
        return nil
      }
      return data as Data
    }

    if targetFormat == .webp {
      let options = [SDImageCoderOption.encodeCompressionQuality: Float(quality) / 100.0] as [SDImageCoderOption: Any]
      return SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: options)
    }

    if targetFormat == .png {
      return image.pngData()
    }

    return image.jpegData(compressionQuality: CGFloat(quality) / 100.0)
  }

  static func attachMetadata(
    originalData: Data,
    compressedData: Data,
    preserveOriginalOrientation: Bool
  ) -> Data? {
    guard let originalSource = CGImageSourceCreateWithData(originalData as CFData, nil),
          let compressedSource = CGImageSourceCreateWithData(compressedData as CFData, nil),
          let rawProperties = CGImageSourceCopyPropertiesAtIndex(originalSource, 0, nil) as? [CFString: Any] else {
      return nil
    }

    let destinationType = CGImageSourceGetType(compressedSource) ?? CGImageSourceGetType(originalSource)
    guard let destinationType else {
      return nil
    }

    let properties = filteredMetadata(
      from: rawProperties,
      destinationType: destinationType,
      preserveOriginalOrientation: preserveOriginalOrientation
    )

    let data = NSMutableData()
    guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, destinationType, 1, nil) else {
      return nil
    }

    CGImageDestinationAddImageFromSource(destination, compressedSource, 0, properties)
    guard CGImageDestinationFinalize(destination) else {
      return nil
    }
    return data as Data
  }

  static func correctedTargetSize(
    for orientation: CGImagePropertyOrientation,
    targetWidth: Int,
    targetHeight: Int,
    autoCorrectionAngle: Bool
  ) -> (width: Int, height: Int) {
    guard autoCorrectionAngle else {
      return (targetWidth, targetHeight)
    }

    if shouldSwapDimensions(for: orientation) {
      return (targetHeight, targetWidth)
    }
    return (targetWidth, targetHeight)
  }

  static func shouldSwapDimensions(for orientation: CGImagePropertyOrientation) -> Bool {
    switch orientation {
    case .left, .leftMirrored, .right, .rightMirrored:
      return true
    default:
      return false
    }
  }

  static func decodeImage(
    source: CGImageSource,
    targetWidth: Int,
    targetHeight: Int,
    applyTransform: Bool
  ) -> UIImage? {
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
          let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat,
          pixelWidth > 0,
          pixelHeight > 0 else {
      return fallbackDecodedImage(source: source, applyTransform: applyTransform)
    }

    let targetSize = constrainedPixelSize(
      sourceWidth: Int(pixelWidth),
      sourceHeight: Int(pixelHeight),
      maxWidth: targetWidth,
      maxHeight: targetHeight
    )
    let maxPixel = max(1, max(targetSize.width, targetSize.height))

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: applyTransform,
      kCGImageSourceThumbnailMaxPixelSize: maxPixel
    ]

    if let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
      return UIImage(cgImage: thumbnail, scale: 1, orientation: .up)
    }

    return fallbackDecodedImage(source: source, applyTransform: applyTransform)
  }

  static func decodeWebPImage(
    _ data: Data,
    targetWidth: Int,
    targetHeight: Int,
    applyTransform: Bool
  ) -> UIImage? {
    var options: [SDImageCoderOption: Any] = [:]
    let boundedSize = CGSize(
      width: max(0, targetWidth),
      height: max(0, targetHeight)
    )
    if boundedSize != .zero {
      options[.decodeThumbnailPixelSize] = boundedSize
      options[.decodePreserveAspectRatio] = true
    }

    guard let decoded = SDImageWebPCoder.shared.decodedImage(
      with: data,
      options: options.isEmpty ? nil : options
    ) else {
      return nil
    }

    let transformedImage: UIImage
    if applyTransform {
      let orientation = imageOrientation(for: data)
      if let cgImage = cgImage(for: decoded) {
        transformedImage = UIImage(cgImage: cgImage, scale: 1, orientation: orientation).normalizedToScale1()
      } else {
        transformedImage = decoded.normalizedToScale1()
      }
    } else {
      transformedImage = decoded.normalizedToScale1()
    }

    return transformedImage
  }

  static func constrainedPixelSize(
    sourceWidth: Int,
    sourceHeight: Int,
    maxWidth: Int,
    maxHeight: Int
  ) -> (width: Int, height: Int) {
    guard sourceWidth > 0, sourceHeight > 0 else {
      return (sourceWidth, sourceHeight)
    }

    let hasWidth = maxWidth > 0
    let hasHeight = maxHeight > 0
    guard hasWidth || hasHeight else {
      return (sourceWidth, sourceHeight)
    }

    let widthRatio = hasWidth ? CGFloat(maxWidth) / CGFloat(sourceWidth) : 1
    let heightRatio = hasHeight ? CGFloat(maxHeight) / CGFloat(sourceHeight) : 1
    let scaleRatio = min(1, min(widthRatio, heightRatio))

    return (
      width: max(1, Int(floor(CGFloat(sourceWidth) * scaleRatio))),
      height: max(1, Int(floor(CGFloat(sourceHeight) * scaleRatio)))
    )
  }

  static func cgImageOrientation(for data: Data) -> CGImagePropertyOrientation {
    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let orientation = sourceOrientation(for: source) else {
      return .up
    }

    return orientation
  }

  private static func cgImage(for image: UIImage) -> CGImage? {
    if let cgImage = image.cgImage {
      return cgImage
    }

    guard let ciImage = image.ciImage else {
      return nil
    }

    let context = CIContext(options: nil)
    return context.createCGImage(ciImage, from: ciImage.extent)
  }

  private static func fallbackDecodedImage(source: CGImageSource, applyTransform: Bool) -> UIImage? {
    guard let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
      return nil
    }

    if applyTransform {
      let orientation = imageOrientation(for: source)
      return UIImage(cgImage: image, scale: 1, orientation: orientation).normalizedToScale1()
    }

    return UIImage(cgImage: image, scale: 1, orientation: .up)
  }

  private static func imageOrientation(for source: CGImageSource) -> UIImage.Orientation {
    switch sourceOrientation(for: source) ?? .up {
    case .up:
      return .up
    case .upMirrored:
      return .upMirrored
    case .down:
      return .down
    case .downMirrored:
      return .downMirrored
    case .left:
      return .left
    case .leftMirrored:
      return .leftMirrored
    case .right:
      return .right
    case .rightMirrored:
      return .rightMirrored
    @unknown default:
      return .up
    }
  }

  private static func sourceOrientation(for source: CGImageSource) -> CGImagePropertyOrientation? {
    guard let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let orientationValue = (properties[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value,
          let orientation = CGImagePropertyOrientation(rawValue: orientationValue) else {
      return nil
    }

    return orientation
  }

  private static func filteredMetadata(
    from rawProperties: [CFString: Any],
    destinationType: CFString,
    preserveOriginalOrientation: Bool
  ) -> CFDictionary {
    let destinationTypeString = destinationType as String
    var metadata = rawProperties

    for key in topLevelKeysToRemove(for: destinationTypeString) {
      metadata.removeValue(forKey: key)
    }

    for (key, value) in metadata {
      metadata[key] = sanitizeMetadataValue(value, parentKey: key)
    }

    metadata[kCGImagePropertyOrientation] = preserveOriginalOrientation
      ? (rawProperties[kCGImagePropertyOrientation] as? NSNumber)?.uint32Value ?? 1
      : 1

    return metadata as CFDictionary
  }

  private static func topLevelKeysToRemove(for destinationType: String) -> Set<CFString> {
    var keys: Set<CFString> = [
      kCGImagePropertyPixelWidth,
      kCGImagePropertyPixelHeight,
      kCGImagePropertyDepth,
      kCGImagePropertyFileSize,
      kCGImagePropertyOrientation
    ]

    if destinationType != "public.jpeg" {
      keys.insert(kCGImagePropertyJFIFDictionary)
    }

    if destinationType != "public.png" {
      keys.insert(kCGImagePropertyPNGDictionary)
    }

    return keys
  }

  private static func sanitizeMetadataValue(_ value: Any, parentKey: CFString?) -> Any {
    if let dictionary = value as? [CFString: Any] {
      return sanitizeMetadataDictionary(dictionary, parentKey: parentKey) as Any
    }

    if let dictionary = value as? [String: Any] {
      var result: [String: Any] = [:]
      for (key, nestedValue) in dictionary {
        if shouldRemoveMetadataKey(key, parentKey: parentKey) {
          continue
        }
        result[key] = sanitizeMetadataValue(nestedValue, parentKey: parentKey)
      }
      return result
    }

    if let array = value as? [Any] {
      return array.map { sanitizeMetadataValue($0, parentKey: parentKey) }
    }

    return value
  }

  private static func sanitizeMetadataDictionary(
    _ dictionary: [CFString: Any],
    parentKey: CFString?
  ) -> [CFString: Any] {
    var result: [CFString: Any] = [:]
    for (key, value) in dictionary {
      if shouldRemoveMetadataKey(key, parentKey: parentKey) {
        continue
      }
      result[key] = sanitizeMetadataValue(value, parentKey: key)
    }
    return result
  }

  private static func shouldRemoveMetadataKey(_ key: CFString, parentKey: CFString?) -> Bool {
    let keyString = key as String
    let lowercased = keyString.lowercased()

    if key == kCGImagePropertyOrientation
      || key == kCGImagePropertyPixelWidth
      || key == kCGImagePropertyPixelHeight
      || key == kCGImagePropertyDepth
      || key == kCGImagePropertyFileSize
      || key == kCGImagePropertyExifPixelXDimension
      || key == kCGImagePropertyExifPixelYDimension {
      return true
    }

    if lowercased.contains("thumbnail")
      || lowercased.contains("preview")
      || lowercased.contains("makernote")
      || lowercased.contains("jfxx") {
      return true
    }

    if let parentKey, parentKey == kCGImagePropertyPNGDictionary {
      return lowercased == "width" || lowercased == "height"
    }

    return false
  }
}
