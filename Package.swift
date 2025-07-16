// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "SmileID",
  defaultLocalization: "en",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "SmileID",
      targets: ["SmileID"])
  ],
  dependencies: [
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", .upToNextMajor(from: "0.9.0")),
    .package(url: "https://github.com/airbnb/lottie-spm", from: "4.5.0"),
    .package(url: "https://github.com/fingerprintjs/fingerprintjs-ios", from: "1.5.0"),
    .package(url: "https://github.com/smileidentity/smile-id-security", from: "1.0.4"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", from: "8.53.2")
  ],
  targets: [
    .target(
      name: "SmileID",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios"),
        .product(name: "Lottie", package: "lottie-spm"),
        .product(name: "SmileIDSecurity", package: "smile-id-security"),
        .product(name: "Sentry", package: "sentry-cocoa")
      ],
      path: "Sources/SmileID",
      resources: [.process("Resources")]),
    .testTarget(
      name: "SmileIDTests",
      dependencies: ["SmileID"],
      path: "Tests")
  ])
