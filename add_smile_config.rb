require 'xcodeproj'
require 'fileutils'

project_path = 'Example/SmileID.xcodeproj'
project = Xcodeproj::Project.open(project_path)

#create file reference
main_group = project.groups.find { |group| group.display_name == 'Example' }
# puts("Japhet is #{project.groups}")
smile_config_reference = main_group.new_file('smile_config.json')

#set target membership
target = project.targets.find { |t| t.name == 'SmileID_Example' }
target.source_build_phase.add_file_reference(smile_config_reference)

#copy to referenced directory
source_file_path = 'smile_config.json'
destination_file_path = smile_config_reference.real_path.to_s

FileUtils.cp(source_file_path, destination_file_path)

#add file reference to build phase
resources_build_phase = target.resources_build_phase
resources_build_phase.add_file_reference(smile_config_reference)

project.save