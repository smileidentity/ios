Pod::Spec.new do |s|
  s.name    = 'SmileIDSDK'
  s.version = '11.2.3'
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
  s.source = { :http => 'https://github.com/smileidentity/ios/releases/download/v11.2.3/SmileIDSDK-xcframeworks-v11.2.3.zip', :sha256 => '67878f7ea0f457895fe6c5e86b1c39c2f66037bfb195bc8a962a479af6dfef0e' }
  s.vendored_frameworks = 'SmileIDSDK-xcframeworks/SmileIDSDK.xcframework', 'SmileIDSDK-xcframeworks/Lottie.xcframework'

  s.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES'
  }
end
