import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
    name: "SmileID",
    organizationName: "SmileID",
    targets: [
        .target(
            name: "SmileID",
            destinations: .iOS,
            product: .app,
            bundleId: "com.smileidentity.example-ios",
            sources: ["Example/SmileID/**"],
            resources: ["Example/SmileID/Resources**"],
             dependencies: [
               .target(name: "sdk"),
            ]
        ),
        .target(
            name: "SmileIDTests",
            destinations: .iOS,
            product: .unitTests,
            bundleId: "com.smileidentity.example-ios",
            infoPlist: .default,
            sources: ["Tests/**"],
            resources: [],
            dependencies: [.target(name: "SmileID")]
        ),
       sdk
    ]
)
