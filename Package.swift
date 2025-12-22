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
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
    .package(url: "https://github.com/airbnb/lottie-spm", exact: "4.5.2"),
    .package(url: "https://github.com/fingerprintjs/fingerprintjs-ios", exact: "1.6.0"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", exact: "9.1.0")
  ],
  targets: [
    .target(
      name: "SmileID",
      dependencies: [
        "SmileIDSDK",
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "Lottie", package: "lottie-spm"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios"),
        .product(name: "Sentry", package: "sentry-cocoa")
      ],
      path: "Sources",
      sources: ["Classes"]
    ),
    .binaryTarget(
      name: "SmileIDSDK",
      url: "https://github.com/smileidentity/ios/releases/download/v11.1.4/SmileIDSDK.xcframework.zip",
      checksum: "6aa2e4200cbeeb05b5727075445dd48c6f82edd3495815a0f8bc1a5135f8855a"
    )
  ]
)
