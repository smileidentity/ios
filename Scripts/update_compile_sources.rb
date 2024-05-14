# We use the Example/SmileID.xcworkspace when
# updating that it won't update the
# SmileID.xcodeproj on the root of the project
# Which is used for SPM and Carthage
# this will not affect the Example project
require 'xcodeproj'

project_path = 'SmileID.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Update a target with the Swift files
def update_target(project, target_name)
  target = project.targets.find { |t| t.name == target_name }
  return unless target

  sources_build_phase = target.source_build_phase

  # Remove all files
  sources_build_phase.clear

  # Add all Swift files from the Sources folder in alphabetical order
  Dir.glob(File.join('Sources', '**', '*.swift')).sort.each do |file|
    sources_build_phase.add_file_reference(project.new_file(file))
  end
end

# Update both SmileID and SmileIDFramework targets
update_target(project, 'SmileID')
update_target(project, 'SmileIDFramework')

project.save
