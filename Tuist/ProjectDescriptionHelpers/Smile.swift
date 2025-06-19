import ProjectDescription

public let sdk = Target.target(
    name: "sdk",
    destinations: .iOS,
    product: .framework,
    bundleId: "com.smileidentity.sdk",
    sources: ["Sources/Smile/Classes/"],
//    resources: ["Sources/Smile/Resources/"],
    dependencies: [
        .external(name: "ZIPFoundation"),
        .external(name: "FingerprintJS"),
        .external(name: "Lottie"),
        .external(name: "SmileIDSecurity")
    ]
)
