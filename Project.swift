import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "SmileID",
    organizationName: "SmileID",
    targets: [
        .target(
            name: "SmileID-Sample",
            destinations: .iOS,
            product: .app,
            bundleId: "com.smileidentity.example-ios",
            deploymentTargets: .iOS("14.0"),
            sources: ["Example/SmileID/**"],
            resources: ["Example/SmileID/Resources/**"],
            dependencies: [
               .target(name: "SmileID")
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "99P7YGX9Q6",
                    "CODE_SIGN_STYLE": "Automatic",
                    "CODE_SIGN_IDENTITY": "SmileID",
                ]
            ),
        ),
        .target(
            name: "SmileIDExampleTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.smileidentity.example-ios",
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            dependencies: [.target(name: "SmileID-Sample")]
        ),
        SmileID
    ]
)
