// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "image_compress_plus_ios",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "image-compress-plus-ios", targets: ["image_compress_plus_ios"])
  ],
  dependencies: [
    .package(url: "https://github.com/SDWebImage/SDWebImage.git", from: "5.17.0"),
    .package(url: "https://github.com/SDWebImage/SDWebImageWebPCoder.git", from: "0.14.0")
  ],
  targets: [
    .target(
      name: "image_compress_plus_ios",
      dependencies: [
        .product(name: "SDWebImage", package: "SDWebImage"),
        .product(name: "SDWebImageWebPCoder", package: "SDWebImageWebPCoder")
      ]
    )
  ]
)
