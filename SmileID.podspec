#
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

  s.description      = <<-DESC
Smile Identity SDK for selfie capture, identity card verification and Smile KYC Job submissions
                       DESC

  s.homepage         = 'https://docs.smileidentity.com/mobile/ios'
  s.license          = 'MIT'
  s.author           = { 'Smile ID' => 'mobile@smileidentity.com' }
  s.source           = { :http => "https://smile-sdks.s3.us-west-2.amazonaws.com/ios-releases/#{s.version}/SmileIdentity.zip"}
  s.vendored_frameworks = "SmileIdentity.xcframework"
  s.ios.deployment_target = '13.0'
  s.swift_version    = "5.8"
  s.swift_versions   = ["5.7", "5.8"]
  s.resource_bundles = {
			'SmileID_SmileID' => ['Sources/Resources/Media.xcassets','Sources/Resources/Fonts/*.ttf','Sources/Localization//*.lproj/*.strings'],
		}
  s.dependency "Zip",'~> 2.1'
end
