// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SmileIdentity",
    defaultLocalization: "en",
    platforms: [.iOS(.v13)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SmileIdentity",
            targets: ["SmileIdentity","SmileIdentityStub"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .binaryTarget(
              name: "SmileIdentity",
              url: "https://smile-sdks.s3.us-west-2.amazonaws.com/cocoapods/2.1.33/Smile_Identity_SDK.zip",//only testing for now
              checksum: "1d06b2e44198ef50c3c03e4ed6c2d68980811ab578fee090a73ad5c447374e9a"),
        // Without at least one regular (non-binary) target, this package doesn't show up
       // in Xcode under "Frameworks, Libraries, and Embedded Content". That prevents
       // Lottie from being embedded in the app product, causing the app to crash when
       // ran on a physical device. As a workaround, we can include a stub target
       // with at least one source file.
        .target(name: "SmileIdentityStub"),
        .testTarget(
            name: "SmileIdentityTests",
            dependencies: ["SmileIdentity"]),
    ]
)
