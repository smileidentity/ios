# Smile ID iOS SDK
<p align="center">
<a href="https://apps.apple.com/us/app/smile-id/id6448359701?itscg=30200&amp;itsct=apps_box_appicon" style="width: 170px; height: 170px; border-radius: 22%; overflow: hidden; display: inline-block; vertical-align: middle;"><img src="https://is1-ssl.mzstatic.com/image/thumb/Purple221/v4/30/4a/94/304a94c9-239c-e460-c7e0-702cc8945827/AppIcon-1x_U007emarketing-0-10-0-85-220-0.png/540x540bb.jpg" alt="Smile ID" style="width: 170px; height: 170px; border-radius: 22%; overflow: hidden; display: inline-block; vertical-align: middle;"></a>
</p>


![Cocoapods Version](https://img.shields.io/cocoapods/v/SmileID)

Smile ID provides the best solutions for Real Time Digital KYC, Identity Verification, User
Onboarding, and User Authentication across Africa.

If you haven’t already, 
[sign up](https://usesmileid.com/talk-to-an-expert) for a free Smile ID account, which comes
with Sandbox access.

Please see [CHANGELOG.md](CHANGELOG.md) or 
[Releases](https://github.com/smileidentity/ios/releases) for the most recent version and 
release notes

<a href="https://apps.apple.com/us/app/smile-id/id6448359701?itsct=apps_box_badge&amp;itscg=30200" style="display: inline-block; overflow: hidden; border-radius: 13px; width: 250px; height: 83px;"><img src="https://tools.applemediaservices.com/api/badges/download-on-the-app-store/black/en-us?size=250x83&amp;releaseDate=1710028800" alt="Download on the App Store" style="border-radius: 13px; width: 250px; height: 83px;"></a>

## Getting Started

Full documentation is available at https://docs.usesmileid.com/integration-options/mobile

The [sample app](Example) included in 
this repo is a good reference implementation

#### 0. Requirements

- iOS 13 and above
- Xcode 14 and above

#### 1. Installation

The SDK is available via CocoaPods and Swift Package Manager. 

To integrate SmileID into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
pod 'SmileID'
```
You can add SmileID as a dependency by adding it to the `dependencies` value of your `Package.swift`

```swift
dependencies: [
    .package(url: "https://github.com/smileidentity/ios.git", .upToNextMajor(from: "<latest-version>"))
]
```

#### 2. Smile Config

Please download your `smile_config.json` file from the 
[Smile ID Portal](https://portal.usesmileid.com/sdk) and add it to your project. 
Ensure the file is added to your app's target.

#### 3. Initialization

Initialize the SDK in your AppDelegate's `application(_:didFinishLaunchingWithOptions:)` method 
or the SceneDelegate's `scene(_:willConnectTo:options:)` depending on your app's structure.

```swift
let config = try? Config(url: Constant.configUrl)
SmileID.initialize(config: config)
```

## UI Components

All UI functionality is exposed via SwiftUI views. To support UIKit, 
embed the views in a `UIHostingController`. All views are available under the `SmileID` object. 

e.g.
```swift
SmileID.smartSelfieEnrollmentScreen()
SmileID.smartSelfieAuthenticationScreen()
```

#### Theming

To customise the colors and typography of the SDK screens, you need to create a 
class that conforms to `SmileIdTheme` protocol. This protocol exposes the cutomisable UI elements on the SDK.

## API

To make raw API requests, you can use `SmileID.api`

## Getting Help

For detailed documentation, please visit https://docs.usesmileid.com/integration-options/mobile

If you require further assistance, you can 
[file a support ticket](https://portal.usesmileid.com/partner/support/tickets) or 
[contact us](https://www.usesmileid.com/contact-us/)

## Contributing

Bug reports and Pull Requests are welcomed. Please see [CONTRIBUTING.md](CONTRIBUTING.md)

## License

[MIT License](LICENSE)
