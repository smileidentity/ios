import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "SmileID",
  organizationName: "SmileID",
  targets: [
    .target(
      name: "Sample",
      destinations: .iOS,
      product: .app,
      bundleId: "com.smileidentity.example-ios",
      deploymentTargets: .iOS("14.0"),
      infoPlist: InfoPlist(stringLiteral: "Example/SmileID/Info.plist"),
      sources: ["Example/SmileID/**"],
      resources: [
        "Example/SmileID/Base.lproj/*.{xib}",
        "Example/SmileID/Resources/**/*.{xcassets,png,strings}",
        "Example/SmileID/Models/**/*.{xcdatamodeld}",
        "Example/SmileID/*.{json}"
      ],
      dependencies: [
        .target(name: "SmileID")
      ],
      settings: .settings(
        base: [
          "DEVELOPMENT_TEAM": "99P7YGX9Q6",
          "CODE_SIGN_STYLE": "Automatic",
          "CODE_SIGN_IDENTITY": "Apple Development"
        ]
      )
    ),
    .target(
      name: "SmileIDExampleTests",
      destinations: .iOS,
      product: .unitTests,
      bundleId: "com.smileidentity.example-ios",
      sources: ["Tests/**"],
      resources: [],
      dependencies: [.target(name: "Sample")]
    ),
    SmileID
  ]
)
