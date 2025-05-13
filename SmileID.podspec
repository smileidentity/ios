Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '10.5.2'
  s.summary          = 'The Official Smile Identity iOS SDK.'
  s.homepage         = 'https://docs.usesmileid.com/integration-options/mobile/ios-v10-beta'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Japhet' => 'japhet@usesmileid.com', 'Juma Allan' => 'juma@usesmileid.com', 'Vansh Gandhi' => 'vansh@usesmileid.com', 'Tobi Omotayo' => 'oluwatobi@usesmileid.com' }
  s.source           = { :git => "https://github.com/smileidentity/ios.git", :tag => "v10.5.2" }
  s.ios.deployment_target = '13.0'
  s.dependency 'ZIPFoundation', '~> 0.9'
  s.dependency 'FingerprintJS'
  s.dependency 'lottie-ios', '~> 4.5.0'
  s.dependency 'SmileIDSecurity', '~> 1.0.1'
  s.swift_version = '5.5'
  s.source_files = 'Sources/SmileID/Classes/**/*'
  s.resource_bundles = {
    'SmileID_SmileID' => ['Sources/SmileID/Resources/**/*.{storyboard,storyboardc,xib,nib,xcassets,json,png,ttf,lproj,xcprivacy,mlmodel,mlmodelc,lottie}']
  }
end
