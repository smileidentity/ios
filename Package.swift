// swift-tools-version:5.9

import PackageDescription

let package = Package(
  name: "SmileID",
  defaultLocalization: "en",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "SmileID",
      targets: ["SmileID"]
    )
  ],
  dependencies: [
    // SmileIDSDK dynamically links Lottie; the pin must match the version the binary was built against.
    .package(url: "https://github.com/airbnb/lottie-spm", exact: "4.5.2")
  ],
  targets: [
    .target(
      name: "SmileID",
      dependencies: [
        "SmileIDSDK",
        .product(name: "Lottie", package: "lottie-spm")
      ],
      path: "Sources",
      sources: ["Classes"]
    ),
    .binaryTarget(
      name: "SmileIDSDK",
      url: "https://github.com/smileidentity/ios/releases/download/v11.2.3/SmileIDSDK.xcframework.zip",
      checksum: "80f284716109bb38c2b1e7fe358c24c2930f719dbb78866a567cdb7c0909d11a"
    )
  ]
)
