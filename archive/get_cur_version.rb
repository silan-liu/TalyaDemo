# sudo gem install xcodeproj

require 'xcodeproj'
require_relative 'get_version'

def get_cur_version(xcodeproj_path)
	version = get_version(xcodeproj_path)

	return version
end

def get_cur_build_version(xcodeproj_path)
	version = get_build_version(xcodeproj_path)

	return version
end

version_type_value = ARGV[0]
xcodeproj_path = ARGV[1]

if version_type_value.nil? || version_type_value.empty?
	version_type_value = '0'
end

if xcodeproj_path.nil? || xcodeproj_path.empty?
	xcodeproj_path = '../ctrtc-meeting-app/ctrtc-meeting-app.xcodeproj'
end

if version_type_value == "0"
	puts get_cur_version(xcodeproj_path)
elsif version_type_value == "1"
	puts get_cur_build_version(xcodeproj_path)
end
