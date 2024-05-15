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
        .package(url: "https://github.com/marmelroy/Zip", .upToNextMajor(from: "2.1.0")),
        .package(url: "https://github.com/airbnb/lottie-spm.git", from: "4.4.2")
    ],
    targets: [
        .target(
            name: "SmileID",
            dependencies: ["Zip", "Lottie"],
            path: "Sources/SmileID",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SmileIDTests",
            dependencies: ["SmileID"],
            path: "Tests"
        )
    ]
)
