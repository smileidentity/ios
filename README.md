# SmileID for Swift Package Manager

This repo provides Swift Package Manager support for [SmileID](https://docs.smileidentity.com/). 

### Installing SmileID

To install SmileID using [Swift Package Manager](https://github.com/apple/swift-package-manager) you can follow the [tutorial published by Apple](https://developer.apple.com/documentation/xcode/adding_package_dependencies_to_your_app) using the URL for this repo with the current version:

1. In Xcode, select “File” → “Add Packages...”
1. Enter https://github.com/smileidentity/iOS.git

or you can add the following dependency to your `Package.swift`:

```swift
.package(url: "https://github.com/smileidentity/iOS.git", from: "0.0.0")
```


### Other Package Managers

SmileID is also available via Cocoapods, More information is available in the main [SmileID](https://docs.smileidentity.com/) repo.
