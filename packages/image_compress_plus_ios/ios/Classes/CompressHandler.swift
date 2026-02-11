import Foundation
import UIKit
import ImageIO
import SDWebImage
import SDWebImageWebPCoder

final class CompressHandler {
  static func compressWithData(
    _ data: Data,
    minWidth: Int,
    minHeight: Int,
    quality: Int,
    rotate: Int,
    format: Int,
    inSampleSize: Int
  ) -> Data? {
    let image: UIImage?
    if isWebP(data) {
      image = SDImageWebPCoder.shared.decodedImage(with: data, options: nil)
      guard let uiImage = image else {
        return nil
      }
      return compressWithUIImage(
        uiImage,
        minWidth: minWidth,
        minHeight: minHeight,
        quality: quality,
        rotate: rotate,
        format: format
      )
    }

    guard var uiImage = decodeImage(
      data,
      minWidth: minWidth,
      minHeight: minHeight,
      inSampleSize: inSampleSize
    ) else {
      return nil
    }

    if ImageCompressPlugin.showLog() {
      NSLog("width = %.0f", uiImage.size.width)
      NSLog("height = %.0f", uiImage.size.height)
      NSLog("minWidth = %d", minWidth)
      NSLog("minHeight = %d", minHeight)
      NSLog("format = %d", format)
    }

    if rotate % 360 != 0 {
      uiImage = uiImage.rotate(deg: CGFloat(rotate))
    }

    return compressData(with: uiImage, quality: quality, format: format)
  }

  static func compressWithUIImage(
    _ image: UIImage,
    minWidth: Int,
    minHeight: Int,
    quality: Int,
    rotate: Int,
    format: Int
  ) -> Data? {
    if ImageCompressPlugin.showLog() {
      NSLog("width = %.0f", image.size.width)
      NSLog("height = %.0f", image.size.height)
      NSLog("minWidth = %d", minWidth)
      NSLog("minHeight = %d", minHeight)
      NSLog("format = %d", format)
    }

    var scaled = image.scaleWithMinWidth(CGFloat(minWidth), minHeight: CGFloat(minHeight))
    if rotate % 360 != 0 {
      scaled = scaled.rotate(deg: CGFloat(rotate))
    }

    return compressData(with: scaled, quality: quality, format: format)
  }

  static func compressDataWithUIImage(
    _ image: UIImage,
    minWidth: Int,
    minHeight: Int,
    quality: Int,
    rotate: Int,
    format: Int
  ) -> Data? {
    var scaled = image.scaleWithMinWidth(CGFloat(minWidth), minHeight: CGFloat(minHeight))
    if rotate % 360 != 0 {
      scaled = scaled.rotate(deg: CGFloat(rotate))
    }
    return compressData(with: scaled, quality: quality, format: format)
  }

  private static func compressData(with image: UIImage, quality: Int, format: Int) -> Data? {
    if format == 2 { // heic
      guard #available(iOS 11.0, *), let cgImage = image.cgImage else {
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

    if format == 3 { // webp
      let options = [SDImageCoderOption.encodeCompressionQuality: Float(quality) / 100.0] as [SDImageCoderOption: Any]
      return SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: options)
    }

    if format == 1 { // png
      return image.pngData()
    }

    return image.jpegData(compressionQuality: CGFloat(quality) / 100.0)
  }

  private static func isWebP(_ data: Data) -> Bool {
    guard data.count >= 12 else {
      return false
    }
    let riffRange = 8..<12
    let riff = data.subdata(in: riffRange)
    return String(data: riff, encoding: .ascii) == "WEBP"
  }

  private static func decodeImage(
    _ data: Data,
    minWidth: Int,
    minHeight: Int,
    inSampleSize: Int
  ) -> UIImage? {
    guard minWidth > 0, minHeight > 0 else {
      return UIImage(data: data)
    }

    guard let source = CGImageSourceCreateWithData(data as CFData, nil),
          let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any],
          let pixelWidth = properties[kCGImagePropertyPixelWidth] as? CGFloat,
          let pixelHeight = properties[kCGImagePropertyPixelHeight] as? CGFloat,
          pixelWidth > 0, pixelHeight > 0 else {
      return UIImage(data: data)
    }

    let imgRatio = pixelWidth / pixelHeight
    let maxRatio = CGFloat(minWidth) / CGFloat(minHeight)
    var scaleRatio: CGFloat = 1
    if imgRatio < maxRatio {
      scaleRatio = CGFloat(minWidth) / pixelWidth
    } else {
      scaleRatio = CGFloat(minHeight) / pixelHeight
    }
    scaleRatio = min(1, scaleRatio)
    let sample = max(1, inSampleSize)
    let targetWidth = floor((scaleRatio * pixelWidth) / CGFloat(sample))
    let targetHeight = floor((scaleRatio * pixelHeight) / CGFloat(sample))
    let maxPixel = max(targetWidth, targetHeight)

    let options: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceThumbnailMaxPixelSize: maxPixel
    ]

    if let thumbnail = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary) {
      return UIImage(cgImage: thumbnail)
    }

    return UIImage(data: data)
  }

  static func attachMetadata(originalData: Data, compressedData: Data) -> Data? {
    guard let originalSource = CGImageSourceCreateWithData(originalData as CFData, nil),
          let compressedSource = CGImageSourceCreateWithData(compressedData as CFData, nil),
          let rawProperties = CGImageSourceCopyPropertiesAtIndex(originalSource, 0, nil) else {
      return nil
    }

    let properties: CFDictionary
    if let mutable = (rawProperties as NSDictionary).mutableCopy() as? NSMutableDictionary {
      mutable[kCGImagePropertyOrientation] = 1
      properties = mutable as CFDictionary
    } else {
      properties = rawProperties
    }

    let type = CGImageSourceGetType(compressedSource) ?? CGImageSourceGetType(originalSource)
    guard let destinationType = type else {
      return nil
    }

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
}
