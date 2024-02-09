# We use the Example/SmileID.xcworkspace when
# updating that it may not update the
# SmileID.xcodeproj on the root of the project
require 'xcodeproj'

project_path = 'SmileID.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'SmileIDFramework' }
sources_build_phase = target.source_build_phase

# Remove all files
sources_build_phase.clear

# Add all Swift files from the Sources folder in alphabetical order to avoid
# having these be different every time Carthage is run and or this is run locally
Dir.glob(File.join('Sources', '**', '*.swift')).sort.each do |file|
  sources_build_phase.add_file_reference(project.new_file(file))
end

project.save
