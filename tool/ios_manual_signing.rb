# Switches the Release configuration of the Runner target to manual signing, for the `ios`
# job of release.yml (#241). The committed project keeps automatic signing for local builds;
# CI has no Apple ID, only a distribution certificate and an App Store profile.
#
#   ruby tool/ios_manual_signing.rb ios/Runner.xcodeproj TEAM_ID PROFILE_NAME IDENTITY
#
# Only the Runner target is changed: build settings passed on the xcodebuild command line
# would also apply to the CocoaPods targets, which reject a provisioning profile.
require 'xcodeproj' # dependency of CocoaPods

project_path, team, profile, identity = ARGV
abort "usage: #{$PROGRAM_NAME} PROJECT TEAM_ID PROFILE_NAME IDENTITY" unless identity

project = Xcodeproj::Project.open(project_path)
target = project.targets.find { |t| t.name == 'Runner' } or abort 'No Runner target.'
config = target.build_configurations.find { |c| c.name == 'Release' } or abort 'No Release configuration.'

config.build_settings.merge!(
  'CODE_SIGN_STYLE' => 'Manual',
  'DEVELOPMENT_TEAM' => team,
  'PROVISIONING_PROFILE_SPECIFIER' => profile,
  'CODE_SIGN_IDENTITY' => identity,
  # Overrides the project-level "iPhone Developer" of the Release configuration.
  'CODE_SIGN_IDENTITY[sdk=iphoneos*]' => identity
)
project.save
puts "Runner/Release: manual signing with '#{profile}' and '#{identity}'."
