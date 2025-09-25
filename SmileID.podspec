Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '11.1.1'
  s.summary          = 'The Official Smile Identity iOS SDK.'
  s.homepage         = 'https://docs.usesmileid.com/integration-options/mobile/getting-started'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Japhet' => 'japhet@usesmileid.com', 'Juma Allan' => 'juma@usesmileid.com', 'Vansh Gandhi' => 'vansh@usesmileid.com', 'Tobi Omotayo' => 'oluwatobi@usesmileid.com', 'Harun Wangereka' => 'harun@usesmileid.com' }
  s.source           = { :git => "https://github.com/smileidentity/ios.git", :tag => "v11.1.1" }
  s.ios.deployment_target = '13.0'
  s.dependency 'ZIPFoundation', '0.9.19'
  s.dependency 'FingerprintJS', '1.6.0'
  s.dependency 'lottie-ios', '4.5.2'
  s.dependency 'Sentry', '8.55.1'
  s.dependency 'SmileIDSecurity', '11.1.1'
  s.swift_version = '5.7'
  s.source_files = 'Sources/Classes/**/*'
  s.resource_bundles = {
    'SmileID_SmileID' => ['Sources/Resources/**/*.{storyboard,storyboardc,xib,nib,xcassets,json,png,ttf,lproj,xcprivacy,mlmodel,mlmodelc,lottie}']
  }
end
