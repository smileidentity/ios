Pod::Spec.new do |s|
  s.name    = 'SmileIDSDK'
  s.version = '11.1.11'
  s.summary = 'Binary SmileID SDK module.'
  s.homepage = 'https://docs.usesmileid.com/integration-options/mobile/getting-started'
  s.license  = { :type => 'MIT' }
    s.author           = {
    'Japhet' => 'japhet@usesmileid.com',
    'Juma Allan' => 'juma@usesmileid.com',
    'Vansh Gandhi' => 'vansh@usesmileid.com',
    'Tobi Omotayo' => 'oluwatobi@usesmileid.com',
    'Harun Wangereka' => 'harun@usesmileid.com'
  }
  s.ios.deployment_target = '13.0'
  s.swift_version = '5.9'
  s.source = { :http => 'https://github.com/smileidentity/ios/releases/download/v11.1.11/SmileIDSDK-xcframeworks-v11.1.11.zip', :sha256 => 'fd91accdc13116b05938ff13912b5b7928b15228675ad0e300f58c0c799fedf8' }
  s.vendored_frameworks = 'SmileIDSDK-xcframeworks/SmileIDSDK.xcframework', 'SmileIDSDK-xcframeworks/Lottie.xcframework'

  s.dependency 'ZIPFoundation', '0.9.20'
  s.dependency 'FingerprintJS', '1.6.0'
  s.dependency 'Sentry', '~> 8.57'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
