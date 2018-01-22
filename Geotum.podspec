#
# Be sure to run `pod lib lint Geotum.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
s.name             = 'Geotum'
s.version          = '1.0.0'
s.summary          = 'Convert to/from UTM points for iOS and macOS'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

s.description      = <<-DESC
Converts between UTM and lat/lon pairs on iOS and macOS.
DESC

s.homepage         = 'https://github.com/pducks32/Geotum'
s.license          = { :type => 'MIT', :file => 'LICENSE' }
s.author           = { 'Patrick Metcalfe' => 'git@patrickmetcalfe.com' }
s.source           = { :git => 'https://github.com/pducks32/Geotum.git', :tag => s.version.to_s }
s.social_media_url = 'https://twitter.com/pducks32'

s.ios.deployment_target = '10.0'
s.osx.deployment_target = '10.12'

s.source_files = 'Sources/Geotum/**/*'
end
