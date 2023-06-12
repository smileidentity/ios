#i
# Be sure to run `pod lib lint SmileID.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SmileID'
  s.version          = '0.0.0'
  s.summary          = 'The Official Smile Identity iOS SDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description  = <<-DESC
  Smile Identity SDK for iOS selfie capture, physical id card capture and job submission
  DESC

  s.homepage     = "https://docs.smileidentity.com/mobile/ios"
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license = { :type => 'MIT', :text => <<-LICENSE
                  https://docs.smileidentity.com/  
                 LICENSE
               }
  s.author           = {  'Jubril ' => 'jubril@smileidentity.com', 'Japhet' => 'japhet@smileidentity.com'}
  s.source           = { :http => "https://smile-sdks.s3.us-west-2.amazonaws.com/ios-releases/#{s.version}/SmileID.zip"}
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'
  s.ios.deployment_target = '13.0'
  s.dependency 'Zip', '~> 2.1.0'
  s.swift_version = '5.5'
  
  # dev
  s.source_files = 'SmileID/Classes/**/*'
  s.resource_bundles = {
    'Resources' => ['SmileID/Assets/**/*.{storyboard,storyboardc,xib,nib,xcassets,json,png,ttf,lproj}']
  }
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = 'Tests/*'
  end  


  # release
  # s.vendored_frameworks = "SmileID.xcframework"
  # s.resource_bundles = {
  #   'Resources' => ['SmileID.xcframework/*/SmileID.framework/Resources.bundle']
  # }
end
