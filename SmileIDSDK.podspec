Pod::Spec.new do |s|
  s.name    = 'SmileIDSDK'
  s.version = '11.1.2'
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

  s.source = { :http => 'https://github.com/smileidentity/ios/releases/download/v11.1.2/SmileIDSDK-xcframeworks-v11.1.2.zip', :sha256 => '9ab1e32a6c715f0ddcf5e3692fc586b5455ed2ed3578b03f55d5b078aac64fc9' }
  s.vendored_frameworks = 'SmileIDSDK-xcframeworks/SmileIDSDK.xcframework'

  s.dependency 'ZIPFoundation', '0.9.20'
  s.dependency 'FingerprintJS', '1.6.0'
  s.dependency 'lottie-ios', '4.5.2'
  s.dependency 'Sentry', '8.57.1'
  s.dependency 'SmileIDSecurity', '11.1.2'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
