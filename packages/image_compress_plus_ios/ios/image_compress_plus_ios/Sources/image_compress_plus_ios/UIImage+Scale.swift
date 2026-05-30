import UIKit

extension UIImage {
  func scaleWithMinWidth(_ minWidth: CGFloat, minHeight: CGFloat) -> UIImage {
    var actualHeight = size.height
    var actualWidth = size.width
    let imgRatio = actualWidth / actualHeight
    let maxRatio = minWidth / minHeight
    var scaleRatio: CGFloat = 1

    if imgRatio < maxRatio {
      scaleRatio = minWidth / actualWidth
    } else {
      scaleRatio = minHeight / actualHeight
    }

    scaleRatio = min(1, scaleRatio)
    actualWidth = floor(scaleRatio * actualWidth)
    actualHeight = floor(scaleRatio * actualHeight)

    let rect = CGRect(x: 0, y: 0, width: actualWidth, height: actualHeight)
    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: rect.size, format: format)
    let newImage = renderer.image { _ in
      draw(in: rect)
    }

    if ImageCompressPlugin.showLog() {
      NSLog("scale = %.2f", scaleRatio)
      NSLog("dst width = %.2f", rect.size.width)
      NSLog("dst height = %.2f", rect.size.height)
    }

    return newImage
  }

  func rotate(deg: CGFloat) -> UIImage {
    if ImageCompressPlugin.showLog() {
      NSLog("will rotate %f", deg)
    }

    let radians = deg * .pi / 180
    let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
    let rotatedRect = rect.applying(CGAffineTransform(rotationAngle: radians))
    let rotatedSize = CGSize(width: abs(rotatedRect.width), height: abs(rotatedRect.height))

    let format = UIGraphicsImageRendererFormat()
    format.scale = 1
    let renderer = UIGraphicsImageRenderer(size: rotatedSize, format: format)
    let newImage = renderer.image { context in
      guard let cgImage = self.cgImage else { return }
      let bitmap = context.cgContext
      bitmap.translateBy(x: rotatedSize.width / 2, y: rotatedSize.height / 2)
      bitmap.rotate(by: radians)
      bitmap.scaleBy(x: 1.0, y: -1.0)
      bitmap.draw(cgImage, in: CGRect(x: -size.width / 2, y: -size.height / 2, width: size.width, height: size.height))
    }

    return newImage
  }
}
