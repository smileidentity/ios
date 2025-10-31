// swift-tools-version:5.7

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
    .package(url: "https://github.com/smileidentity/smile-id-security", exact: "11.1.2"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", exact: "8.57.0")
  ],
  targets: [
    .target(
      name: "SmileID",
      dependencies: [
        "SmileIDSDK",
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "Lottie", package: "lottie-spm"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios"),
        .product(name: "Sentry", package: "sentry-cocoa"),
        .product(name: "SmileIDSecurity", package: "smile-id-security")
      ],
      path: "Sources",
      sources: ["Classes"]
    ),
    .binaryTarget(
      name: "SmileIDSDK",
            url: "https://github.com/smileidentity/ios/releases/download/v11.1.2/SmileIDSDK.xcframework.zip",
            checksum: "623d441897a824e7bf7ed41ac55565d27bc266d4f5872ff94f40043dd7654b42"
    )
  ]
)
