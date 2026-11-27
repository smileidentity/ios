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
      url: "https://github.com/smileidentity/ios/releases/download/v11.2.4/SmileIDSDK.xcframework.zip",
      checksum: "3e8fa7844859c926c0f651f734c74abaff9873a589f8749d1d4d925dce23b9ee"
    )
  ]
)
