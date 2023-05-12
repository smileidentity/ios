#
# Be sure to run `pod lib lint SmileIdentity.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'SmileIdentity'
  s.version          = '0.1.0'
  s.summary          = 'The Official Smile Identity iOS SDK.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
Smile Identity SDK for selfie capture, identity card verification and Smile KYC Job submissions
                       DESC

  s.homepage         = 'https://docs.smileidentity.com/mobile/ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Smile ID' => 'mobile@smileidentity.com' }
  s.source           = { :git => 'https://github.com/smileidentity/ios-v2.git', :tag => s.version.to_s }
  s.ios.deployment_target = '13.0'
  s.swift_version = "5.0"
  s.ios.source_files = 'Sources/**/*.swift'
  s.resource_bundles = {
			'com.smileid.ios.resources' => ['Sources/Resources/Media.xcassets','Sources/Resources/Fonts/*.ttf','Sources/Localization//*.lproj/*.strings'],
		}
  s.dependency "Zip",'~> 2.1'
end
