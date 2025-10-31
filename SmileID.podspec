Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '11.1.2'
  s.summary          = 'The Official Smile Identity iOS SDK.'
  s.homepage         = 'https://docs.usesmileid.com/integration-options/mobile/getting-started'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Japhet' => 'japhet@usesmileid.com', 'Juma Allan' => 'juma@usesmileid.com', 'Vansh Gandhi' => 'vansh@usesmileid.com', 'Tobi Omotayo' => 'oluwatobi@usesmileid.com', 'Harun Wangereka' => 'harun@usesmileid.com' }
  s.source           = { :git => 'https://github.com/smileidentity/ios.git', :tag => "v#{s.version}" }
  s.prepare_command = <<-CMD
    set -e
    FRAMEWORK_ZIP="SmileIDSDK-xcframeworks-v#{s.version}.zip"
    FRAMEWORK_URL="https://github.com/smileidentity/ios/releases/download/v#{s.version}/SmileIDSDK-xcframeworks-v#{s.version}.zip"
    rm -rf SmileIDSDK-xcframeworks
    curl -fL -o "${FRAMEWORK_ZIP}" "${FRAMEWORK_URL}"
    unzip -qo "${FRAMEWORK_ZIP}"
    rm "${FRAMEWORK_ZIP}"
  CMD
  s.vendored_frameworks = 'SmileIDSDK-xcframeworks/SmileIDSDK.xcframework'
  s.ios.deployment_target = '13.0'
  s.dependency 'ZIPFoundation', '0.9.20'
  s.dependency 'FingerprintJS', '1.6.0'
  s.dependency 'lottie-ios', '4.5.2'
  s.dependency 'Sentry', '8.57.0'
  s.dependency 'SmileIDSecurity', '11.1.2'
  s.swift_version = '5.7'
  s.source_files = 'Sources/Classes/**/*'
end
