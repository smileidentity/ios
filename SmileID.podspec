Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '10.0.9'
  s.summary          = 'The Official Smile Identity iOS SDK.'
  s.homepage         = 'https://docs.usesmileid.com/integration-options/mobile/ios-v10-beta'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Japhet' => 'japhet@smileidentity.com', 'Juma Allan' => 'juma@smileidentity.com', 'Vansh Gandhi' => 'vansh@smileidentity.com'}
  s.source           = { :git => "https://github.com/smileidentity/ios.git", :tag => "v10.0.9" }
  s.ios.deployment_target = '13.0'
  s.dependency 'Zip', '~> 2.1.0'
  s.swift_version = '5.5'
  s.source_files = 'Sources/SmileID/Classes/**/*'
  s.resource_bundles = {
    'SmileID_SmileID' => ['Sources/SmileID/Resources/**/*.{storyboard,storyboardc,xib,nib,xcassets,json,png,ttf,lproj}']
  }
end
