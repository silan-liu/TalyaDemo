# sudo gem install xcodeproj

require 'xcodeproj'

def version_is_valid(version_str)
  if version_str =~ /(\d+)\.(\d+)\.(\d+)/
    major, minor, patch = $1.to_i, $2.to_i, $3.to_i
    return true
  else
    return false
  end
end


def save_version(new_version)
	project = Xcodeproj::Project.open('../ctrtc-meeting-app/ctrtc-meeting-app.xcodeproj')
	target = project.targets.first

	if target.nil? 
		puts "[update_version] target is nil"
		return
	end

	puts "[update_version] begin save version to #{new_version}"

	target.build_configurations.each do |config|
	   	config.build_settings["MARKETING_VERSION"] = new_version
	end

	project.save
end

def save_build_version(new_build_version)
	project = Xcodeproj::Project.open('../ctrtc-meeting-app/ctrtc-meeting-app.xcodeproj')
	target = project.targets.first

	if target.nil? 
		puts "[update_version] target is nil"
		return
	end

	puts "[update_version] begin save build version to #{new_build_version}"

	target.build_configurations.each do |config|
		config.build_settings["CURRENT_PROJECT_VERSION"] = new_build_version
	end

	project.save
end

version_type_value = ARGV[0]

if version_type_value.nil? || version_type_value.empty?
	version_type_value = '0'
end

new_version = ARGV[1]

if version_type_value == "0"
	if new_version.nil? || new_version.empty?
		puts "[update_version] new_version is empty or not valid"
	elsif !version_is_valid(new_version)
		puts "[update_version] new_version is not valid"
	else
		save_version(new_version)
	end
elsif version_type_value == "1"
	if new_version.nil? || new_version.empty?
		puts "[update_version] new_version is empty or not valid"
	elsif new_version.to_i > 0
		save_build_version(new_version)
	end
end




