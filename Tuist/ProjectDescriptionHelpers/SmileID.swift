import ProjectDescription

public let SmileID = Target.target(
    name: "SmileID",
    destinations: .iOS,
    product: .framework,
    bundleId: "com.smileidentity.ios-sdk",
    deploymentTargets: .iOS("13.0"),
    infoPlist: .default,
    sources: ["Sources/SmileID/Classes/**"],
    resources: [
        "Sources/SmileID/Resources/Fonts/**",
        "Sources/SmileID/Resources/Localization/**",
        "Sources/SmileID/Resources/LottieFiles/**",
        "Sources/SmileID/Resources/Media.xcassets",
        "Sources/SmileID/Resources/devicemodels.json",
        "Sources/SmileID/Resources/PrivacyInfo.xcprivacy",
    ],
    dependencies: [
        .external(name: "ZIPFoundation"),
        .external(name: "FingerprintJS"),
        .external(name: "Lottie"),
        .external(name: "SmileIDSecurity")
    ]
)
