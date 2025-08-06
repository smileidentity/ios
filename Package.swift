// swift-tools-version:5.7

import PackageDescription

let package = Package(
  name: "SmileID",
  defaultLocalization: "en",
  platforms: [.iOS(.v13)],
  products: [
    .library(
      name: "SmileID",
      targets: ["SmileID"]),
    .library(
      name: "UI", 
      targets: ["UI"]),
    .library(
      name: "Networking",
      targets: ["Networking"]),
    .library(
      name: "ML",
      targets: ["ML"]),
    .library(
      name: "Analytics",
      targets: ["Analytics"]),
    .library(
      name: "Storage",
      targets: ["Storage"])
  ],
  dependencies: [
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.19"),
    .package(url: "https://github.com/airbnb/lottie-spm", exact: "4.5.2"),
    .package(url: "https://github.com/fingerprintjs/fingerprintjs-ios", exact: "1.6.0"),
    .package(url: "https://github.com/smileidentity/smile-id-security", exact: "11.1.0"),
    .package(url: "https://github.com/getsentry/sentry-cocoa", exact: "8.54.0")
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
      path: "Sources",
      resources: [.process("Resources")]),
    .target(
      name: "UI",
      dependencies: [
        .product(name: "Lottie", package: "lottie-spm")
      ],
      path: "UI"),
    .target(
      name: "Networking",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "SmileIDSecurity", package: "smile-id-security")
      ],
      path: "Networking"),
    .target(
      name: "ML",
      dependencies: [],
      path: "ML"),
    .target(
      name: "Analytics",
      dependencies: [
        .product(name: "Sentry", package: "sentry-cocoa"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios")
      ],
      path: "Analytics"),
    .target(
      name: "Storage",
      dependencies: [],
      path: "Storage"),
    .testTarget(
      name: "SmileIDTests",
      dependencies: ["SmileID"],
      path: "Tests")
  ])
