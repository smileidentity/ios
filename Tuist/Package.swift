// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SmileID",
    dependencies: [
         .package(
            url: "https://github.com/weichsel/ZIPFoundation",
            from: "0.9.19"
         ),
         .package(
            url: "https://github.com/airbnb/lottie-spm.git",
             from: "4.5.2"
           ),
         .package(
             url: "https://github.com/fingerprintjs/fingerprintjs-ios",
             from: "1.6.0"
           ),
           .package(
             url: "https://github.com/smileidentity/smile-id-security",
             from: "1.0.1"
           )
    ]
)
