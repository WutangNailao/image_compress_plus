import UIKit

extension UIImage {
  var compressionPixelSize: CGSize {
    if let cgImage {
      return CGSize(width: CGFloat(cgImage.width), height: CGFloat(cgImage.height))
    }

    if let ciImage {
      let extent = ciImage.extent.integral
      return CGSize(
        width: max(1, extent.width),
        height: max(1, extent.height)
      )
    }

    let effectiveScale = scale > 0 ? scale : 1
    return CGSize(
      width: CGFloat(max(1, Int(round(size.width * effectiveScale)))),
      height: CGFloat(max(1, Int(round(size.height * effectiveScale))))
    )
  }

  private static func compressionRendererFormat() -> UIGraphicsImageRendererFormat {
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    return format
  }

  func normalizedToScale1() -> UIImage {
    if imageOrientation == .up {
      if scale == 1 {
        return self
      }

      if let cgImage {
        return UIImage(cgImage: cgImage, scale: 1, orientation: .up)
      }
    }

    let sourcePixels = compressionPixelSize
    let renderer = UIGraphicsImageRenderer(
      size: sourcePixels,
      format: Self.compressionRendererFormat()
    )
    return renderer.image { _ in
      draw(in: CGRect(origin: .zero, size: sourcePixels))
    }
  }

  func renderedForCompression(
    maxPixelWidth: Int,
    maxPixelHeight: Int,
    rotateDegrees: CGFloat,
    logEnabled: Bool
  ) -> UIImage {
    let baseImage = normalizedToScale1()
    let sourcePixels = baseImage.compressionPixelSize

    guard sourcePixels.width > 0, sourcePixels.height > 0 else {
      return baseImage
    }

    let normalizedRotation = rotateDegrees.truncatingRemainder(dividingBy: 360)
    let targetPixels = Self.constrainedPixelSize(
      sourcePixels: sourcePixels,
      maxPixelWidth: maxPixelWidth,
      maxPixelHeight: maxPixelHeight
    )

    let widthScale = targetPixels.width / sourcePixels.width
    let heightScale = targetPixels.height / sourcePixels.height
    let scaleRatio = min(widthScale, heightScale)
    if logEnabled {
      if scaleRatio >= 1 {
        NSLog("resize skipped; source already fits target bounds")
      } else {
        NSLog("resize scale = %.4f", scaleRatio)
        NSLog("dst width = %d", Int(targetPixels.width))
        NSLog("dst height = %d", Int(targetPixels.height))
      }
    }

    if logEnabled, normalizedRotation != 0 {
      NSLog("will rotate %f", normalizedRotation)
    }

    let needsResize = Int(targetPixels.width) != Int(sourcePixels.width)
      || Int(targetPixels.height) != Int(sourcePixels.height)
    let needsRotation = normalizedRotation != 0

    if !needsResize && !needsRotation {
      return baseImage
    }

    let radians = normalizedRotation * .pi / 180
    let outputPixels: CGSize
    if needsRotation {
      let rotatedRect = CGRect(origin: .zero, size: targetPixels)
        .applying(CGAffineTransform(rotationAngle: radians))
      outputPixels = CGSize(
        width: max(1, ceil(abs(rotatedRect.width))),
        height: max(1, ceil(abs(rotatedRect.height)))
      )
    } else {
      outputPixels = targetPixels
    }

    let renderer = UIGraphicsImageRenderer(
      size: outputPixels,
      format: Self.compressionRendererFormat()
    )
    return renderer.image { context in
      let bitmap = context.cgContext

      if needsRotation {
        bitmap.translateBy(x: outputPixels.width / 2, y: outputPixels.height / 2)
        bitmap.rotate(by: radians)
        baseImage.draw(
          in: CGRect(
            x: -targetPixels.width / 2,
            y: -targetPixels.height / 2,
            width: targetPixels.width,
            height: targetPixels.height
          )
        )
      } else {
        baseImage.draw(in: CGRect(origin: .zero, size: targetPixels))
      }
    }
  }

  private static func constrainedPixelSize(
    sourcePixels: CGSize,
    maxPixelWidth: Int,
    maxPixelHeight: Int
  ) -> CGSize {
    let hasWidth = maxPixelWidth > 0
    let hasHeight = maxPixelHeight > 0

    guard hasWidth || hasHeight else {
      return sourcePixels
    }

    let widthRatio = hasWidth ? CGFloat(maxPixelWidth) / sourcePixels.width : 1
    let heightRatio = hasHeight ? CGFloat(maxPixelHeight) / sourcePixels.height : 1
    let scaleRatio = min(1, min(widthRatio, heightRatio))

    return CGSize(
      width: CGFloat(max(1, Int(floor(sourcePixels.width * scaleRatio)))),
      height: CGFloat(max(1, Int(floor(sourcePixels.height * scaleRatio))))
    )
  }
}
