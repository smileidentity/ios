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
        // we need next release (after 0.9.18) to fix iOS11 bug, sio we target development branch
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", branch: "development")
    ],
    targets: [
        .target(
            name: "SmileID",
            dependencies: ["ZIPFoundation"],
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
