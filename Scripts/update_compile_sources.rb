require 'xcodeproj'

project_path = '../SmileID.xcodeproj'
project = Xcodeproj::Project.open(project_path)

target = project.targets.find { |t| t.name == 'SmileIDFramework' }
sources_build_phase = target.source_build_phase

# Remove all files
sources_build_phase.clear

# Add all Swift files from the Sources folder
Dir.glob(File.join('Sources', '**', '*.swift')).each do |file|
  sources_build_phase.add_file_reference(project.new_file(file))
end

project.save
