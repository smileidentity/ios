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
      name: "SmileIDAnalytics",
      targets: ["SmileIDAnalytics"]),
    .library(
      name: "SmileIDCamera",
      targets: ["SmileIDCamera"]),
    .library(
      name: "SmileIDML",
      targets: ["SmileIDML"]),
    .library(
      name: "SmileIDNetworking",
      targets: ["SmileIDNetworking"]),
    .library(
      name: "SmileIDStorage",
      targets: ["SmileIDStorage"]),
    .library(
      name: "SmileIDUI",
      targets: ["SmileIDUI"])
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
      name: "SmileIDAnalytics",
      dependencies: [
        .product(name: "Sentry", package: "sentry-cocoa"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios")
      ],
      path: "SmileIDAnalytics/Classes",
      resources: [.process("../Resources")]),
    .target(
      name: "SmileIDCamera",
      dependencies: [],
      path: "SmileIDCamera/Classes",
      resources: [.process("../Resources")]),
    .target(
      name: "SmileIDML",
      dependencies: [],
      path: "SmileIDML/Classes",
      resources: [.process("../Resources")]),
    .target(
      name: "SmileIDNetworking",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "SmileIDSecurity", package: "smile-id-security")
      ],
      path: "SmileIDNetworking/Classes",
      resources: [.process("../Resources")]),
    .target(
      name: "SmileIDStorage",
      dependencies: [],
      path: "SmileIDStorage/Classes",
      resources: [.process("../Resources")]),
    .target(
      name: "SmileIDUI",
      dependencies: [
        .product(name: "Lottie", package: "lottie-spm")
      ],
      path: "SmileIDUI/Classes",
      resources: [.process("../Resources")]),
    .testTarget(
      name: "SmileIDTests",
      dependencies: ["SmileID"],
      path: "Tests"),
    .testTarget(
      name: "SmileIDUITests",
      dependencies: ["SmileIDUI", "SmileID"],
      path: "SmileIDUI/Tests"),
    .testTarget(
      name: "SmileIDAnalyticsTests",
      dependencies: ["SmileIDAnalytics"],
      path: "SmileIDAnalytics/Tests"),
    .testTarget(
      name: "SmileIDCameraTests",
      dependencies: ["SmileIDCamera"],
      path: "SmileIDCamera/Tests"),
    .testTarget(
      name: "SmileIDMLTests",
      dependencies: ["SmileIDML"],
      path: "SmileIDML/Tests"),
    .testTarget(
      name: "SmileIDNetworkingTests",
      dependencies: ["SmileIDNetworking"],
      path: "SmileIDNetworking/Tests"),
    .testTarget(
      name: "SmileIDStorageTests",
      dependencies: ["SmileIDStorage"],
      path: "SmileIDStorage/Tests")
  ])
