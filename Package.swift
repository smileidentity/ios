// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmileID",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SmileID",
            targets: ["SmileID"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/marmelroy/Zip", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SmileID",
            dependencies: ["Zip"],
            path: "Sources",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "SmileIDTests",
            dependencies: ["SmileID"],
            path: "Tests"
        )
    ]
)
