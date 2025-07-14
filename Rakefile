namespace :build do
  desc 'Builds all packages and executables'
  task all: ['package:all', 'example:all', 'xcframework']

  desc 'Builds the Smile ID package for supported platforms'
  namespace :package do
    desc 'Builds the Smile ID package for iOS'
    task all: ['iOS']

    desc 'Builds the Smile ID package for iOS'
    task :iOS do
      xcodebuild('build -scheme "SmileID" -destination generic/platform=iOS')
    end
  end

  desc 'Builds the Smile ID example app for supported platforms'
  namespace :example do
    desc 'Builds the Smile ID example apps for all supported platforms'
    task all: ['iOS']

    desc 'Builds the iOS Smile ID Example app'
    task :iOS do
      xcodebuild('build -scheme "SmileID-Example" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)"')
    end
  end

  desc 'Builds an xcframework for all supported platforms'
  task :xcframework do
    sh 'rm -rf archives'
    sh 'rm -rf SmileID.xcframework'
    sh 'rm -rf release'
    xcodebuild('archive -scheme "SmileID" -destination "generic/platform=iOS Simulator"  -archivePath "archives/ios_simulators.xcarchive" BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO')
    xcodebuild('archive -scheme "SmileID" -destination "generic/platform=iOS"  -archivePath "archives/ios_devices.xcarchive" BUILD_LIBRARY_FOR_DISTRIBUTION=YES SKIP_INSTALL=NO')
    xcarchive('-create-xcframework -framework archives/ios_devices.xcarchive/Products/Library/Frameworks/SmileID.framework -framework archives/ios_simulators.xcarchive/Products/Library/Frameworks/SmileID.framework -output SmileID.xcframework')
    sh 'mkdir release'
    sh 'zip -r SmileID.zip SmileID.xcframework/'
    sh 'sha256sum SmileID.zip > SmileID.sha256'
    sh 'mv SmileID.zip SmileID.sha256 release/'
  end
end

namespace :test do
  desc 'Tests the package , processed the test results and tests spm compatibility'
  task all: ['package', 'process', 'spm','example']
  desc 'Tests the Smile ID package for iOS'
  task :package do
    xcodebuild('test -scheme "SmileID_Tests" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)"')
  end

  desc 'Tests the example app unit tests'
  task :example do
    xcodebuild('test -scheme "SmileID-Example" -destination "platform=iOS Simulator,name=iPhone SE (3rd generation)"')
  end

  desc 'Processes .xcresult artifacts from the most recent test:package execution'
  task :process do
    sh 'mint run ChargePoint/xcparse@2.3.1 xcparse attachments Tests/Artifacts/SmileIDTests.xcresult Tests/Artifacts/TestAttachments'
  end

  desc 'Tests Swift Package Manager support'
  task :spm do
    xcodebuild('build -scheme "SmileID" -destination generic/platform=iOS',"SmileID.xcodeproj")
  end
end

namespace :lint do
  desc 'Lints swift files'
  task :swift do
    sh 'mint run realm/SwiftLint'
  end

  desc 'Lints the CocoaPods podspec'
  task :podspec do
    sh 'pod lib lint SmileID.podspec'
  end
end

namespace :format do
  desc 'Formats swift files'
  task :swift do
    sh 'mint run swiftformat . --swiftversion 5.8'
  end
end

def xcodebuild(command, project = "Example/SmileID.xcworkspace")
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

def xcarchive(command)
  # Check if the mint tool is installed -- if so, pipe the xcodebuild output through xcbeautify
  `which mint`
  sh 'rm -rf ~/Library/Developer/Xcode/DerivedData/* && echo "Successfully flushed DerivedData"'
  if $?.success?
    sh "set -o pipefail && xcodebuild #{command} | mint run thii/xcbeautify@0.10.2"
  else
    sh "xcodebuild #{command}"
  end
end
