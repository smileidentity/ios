
namespace :test do
  desc 'Tests the Smile ID package for iOS'
  task :package do
    xcodebuild('test -scheme "SmileID_Tests" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)"')
  end

  desc 'Tests the example app unit tests'
  task :example do
    xcodebuild('test -scheme "SmileID-Example" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)"')
  end
end

namespace :lint do
  desc 'Lints the CocoaPods podspec'
  task :podspec do
    sh 'xcrun simctl list'
    sh 'xcrun simctl bootstatus booted || xcrun simctl boot "iPhone SE (3rd generation)"'
    sh 'pod lib lint SmileID.podspec --allow-warnings --verbose --no-clean'
  end
end

def xcodebuild(command, project = "Example/SmileID.xcodeproj")
  # Determine the project flag based on the file extension
  project_flag = if project.end_with?(".xcworkspace")
                   "-workspace"
                 elsif project.end_with?(".xcodeproj")
                   "-project"
                 else
                   raise ArgumentError, "Invalid project type. Must be .xcworkspace or .xcodeproj"
                 end

  # Check if the mint tool is installed -- if so, pipe the xcodebuild output through xcbeautify
  `which mint`
  sh 'rm -rf ~/Library/Developer/Xcode/DerivedData/* && echo "Successfully flushed DerivedData"'
  if $?.success?
    sh "set -o pipefail && xcodebuild #{command} #{project_flag} #{project} | mint run thii/xcbeautify@0.10.2"
  else
    sh "xcodebuild #{command} #{project_flag} #{project}"
  end
end
