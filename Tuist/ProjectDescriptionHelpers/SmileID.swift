import ProjectDescription

public let SmileID = Target.target(
    name: "SmileID",
    destinations: .iOS,
    product: .framework,
    bundleId: "com.smileidentity.sdk",
    deploymentTargets: .iOS("13.0"),
    infoPlist: .default,
    sources: ["Sources/SmileID/Classes/**"],
    resources: ["Sources/Smile/Resources/**"],
    dependencies: [
        .external(name: "ZIPFoundation"),
        .external(name: "FingerprintJS"),
        .external(name: "Lottie"),
        .external(name: "SmileIDSecurity")
    ]
)
