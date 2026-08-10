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
    // Lottie is the one real external dependency: SmileIDSDK dynamically links
    // @rpath/Lottie.framework, so the consumer's package graph must supply it,
    // and the exact pin must match the version the binary was built against.
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
      url: "https://github.com/smileidentity/ios/releases/download/v11.2.0/SmileIDSDK.xcframework.zip",
      checksum: "72dcb12072f4bb4d801d836af024c86c47905ec781579e2e4a0ad76006409797"
    )
  ]
)
