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
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.19"),
    .package(url: "https://github.com/airbnb/lottie-spm", exact: "4.5.2"),
    .package(url: "https://github.com/fingerprintjs/fingerprintjs-ios", exact: "1.6.0"),
//    .package(url: "https://github.com/smileidentity/smile-id-security", exact: "11.1.0"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", exact: "8.53.2")
  ],
  targets: [
    .target(
      name: "SmileID",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios"),
        .product(name: "Lottie", package: "lottie-spm"),
//        .product(name: "SmileIDSecurity", package: "smile-id-security"),
        .product(name: "Sentry", package: "sentry-cocoa")
      ],
      path: "Sources",
      resources: [.process("Resources")]),
    .testTarget(
      name: "SmileIDTests",
      dependencies: ["SmileID"],
      path: "Tests")
  ])
