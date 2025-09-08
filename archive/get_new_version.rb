# sudo gem install xcodeproj

require 'xcodeproj'
require_relative 'get_version'

#调用 get_cur_version.rb 中的方法


def increment_version(version_str)
  parts = version_str.split('.')
  last_index = parts.length - 1
  parts[last_index] = (parts[last_index].to_i + 1).to_s
  return parts.join('.')
end

def get_new_version(xcodeproj_path)
	cur_version = get_version(xcodeproj_path)
	new_version = increment_version(cur_version)

	return new_version
end

def get_new_build_version(xcodeproj_path)
	cur_build_version = get_build_version(xcodeproj_path)

	new_build_version = cur_build_version.to_i + 1

	return new_build_version
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
	puts get_new_version(xcodeproj_path)
elsif version_type_value == "1"
	puts get_new_build_version(xcodeproj_path)
end
