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
      name: "SmileIDUI", 
      targets: ["SmileIDUI"]),
    .library(
      name: "SmileIDNetworking",
      targets: ["SmileIDNetworking"]),
    .library(
      name: "SmileIDML",
      targets: ["SmileIDML"]),
    .library(
      name: "SmileIDAnalytics",
      targets: ["SmileIDAnalytics"]),
    .library(
      name: "SmileIDStorage",
      targets: ["SmileIDStorage"])
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
      name: "SmileIDUI",
      dependencies: [
        .product(name: "Lottie", package: "lottie-spm")
      ],
      path: "Sources/SmileIDUI"),
    .target(
      name: "SmileIDNetworking",
      dependencies: [
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "SmileIDSecurity", package: "smile-id-security")
      ],
      path: "Sources/SmileIDNetworking"),
    .target(
      name: "SmileIDML",
      dependencies: [],
      path: "Sources/SmileIDML"),
    .target(
      name: "SmileIDAnalytics",
      dependencies: [
        .product(name: "Sentry", package: "sentry-cocoa"),
        .product(name: "FingerprintJS", package: "fingerprintjs-ios")
      ],
      path: "Sources/SmileIDAnalytics"),
    .target(
      name: "SmileIDStorage",
      dependencies: [],
      path: "Sources/SmileIDStorage"),
    .testTarget(
      name: "SmileIDTests",
      dependencies: ["SmileID"],
      path: "Tests")
  ])
