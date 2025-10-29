Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '11.1.2'
  s.summary          = 'The Official Smile Identity iOS SDK.'
  s.homepage         = 'https://docs.usesmileid.com/integration-options/mobile/getting-started'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Japhet' => 'japhet@usesmileid.com', 'Juma Allan' => 'juma@usesmileid.com', 'Vansh Gandhi' => 'vansh@usesmileid.com', 'Tobi Omotayo' => 'oluwatobi@usesmileid.com', 'Harun Wangereka' => 'harun@usesmileid.com' }
  s.source           = { :http => 'https://github.com/smileidentity/ios/releases/download/v11.1.2/SmileIDSDK-xcframeworks-v11.1.2.zip', :sha256 => '0250201418c498cb3541ba2abcfd9d6c185aed15aedc61e8c303b41efec6a34a' }
  s.ios.deployment_target = '13.0'
  s.dependency 'ZIPFoundation', '0.9.20'
  s.dependency 'FingerprintJS', '1.6.0'
  s.dependency 'lottie-ios', '4.5.2'
  s.dependency 'Sentry', '8.57.0'
  s.dependency 'SmileIDSecurity', '11.1.1'
  s.swift_version = '5.7'
  s.source_files = 'Sources/Classes/**/*'
  s.vendored_frameworks = 'SmileIDSDK-xcframeworks/SmileIDSDK.xcframework'
end
