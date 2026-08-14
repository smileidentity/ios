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
      url: "https://github.com/smileidentity/ios/releases/download/v11.2.1/SmileIDSDK.xcframework.zip",
      checksum: "108ffc595d135d31de4f8731f76d37fd5df0a816affb92206e6ebedd84cb8f36"
    )
  ]
)
