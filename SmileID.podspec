Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '11.0.0'
  s.summary          = 'The Official Smile Identity iOS SDK.'
  s.homepage         = 'https://docs.usesmileid.com/integration-options/mobile/ios-v10-beta'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Japhet' => 'japhet@usesmileid.com', 'Juma Allan' => 'juma@usesmileid.com', 'Vansh Gandhi' => 'vansh@usesmileid.com', 'Tobi Omotayo' => 'oluwatobi@usesmileid.com' }
  s.source           = { :git => "https://github.com/smileidentity/ios.git", :tag => "v11.0.0" }
  s.ios.deployment_target = '13.0'
  s.dependency 'ZIPFoundation', '~> 0.9'
  s.dependency 'FingerprintJS'
  s.dependency 'lottie-ios', '~> 4.5.0'
  s.vendored_framework = 'SmileIDSecurity.xcframework'
  s.swift_version = '5.5'
  s.source_files = 'Sources/SmileID/Classes/**/*'
  s.resource_bundles = {
    'SmileID_SmileID' => ['Sources/SmileID/Resources/**/*.{storyboard,storyboardc,xib,nib,xcassets,json,png,ttf,lproj,xcprivacy,mlmodel,mlmodelc,lottie}']
  }
end
