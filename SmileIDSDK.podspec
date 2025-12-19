Pod::Spec.new do |s|
  s.name    = 'SmileIDSDK'
  s.version = '11.1.4'
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
  s.source = { :http => 'https://github.com/smileidentity/ios/releases/download/v11.1.4/SmileIDSDK-xcframeworks-v11.1.4.zip', :sha256 => '6b3d6a43d89f191b4bd838a2377e22857a49b8bf9f470c067a5655242c0284db' }
  s.vendored_frameworks = 'SmileIDSDK-xcframeworks/SmileIDSDK.xcframework', 'SmileIDSDK-xcframeworks/Lottie.xcframework'

  s.dependency 'ZIPFoundation', '0.9.20'
  s.dependency 'FingerprintJS', '1.6.0'
  s.dependency 'Sentry', '8.57.1'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
