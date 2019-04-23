#
# Be sure to run `pod lib lint Geotum.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
    s.name             = 'Geotum'
    s.version          = '1.4.1'
    s.summary          = 'Convert to/from UTM points for iOS and macOS in Swift.'
    
    s.description      = <<-DESC
    Geotum is a Swift UTM converter that is precise to 1 nanometer. It works on all Apple
    platforms and can convert to and from Latitude Longitude coordinates and UTM points.
    It also includes a ton of helpers to make working with them less error prone and
    all conversions are 100% tested.
    DESC

    s.homepage         = 'https://github.com/pducks32/Geotum'
    s.license          = { :type => 'MIT', :file => 'LICENSE' }
    s.author           = { 'Patrick Metcalfe' => 'git@patrickmetcalfe.com' }
    s.source           = { :git => 'https://github.com/pducks32/Geotum.git', :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/pducks32'

    s.ios.deployment_target = '10.0'
    s.osx.deployment_target = '10.12'
    s.swift_version = '4.0'

    s.source_files = 'Sources/Geotum/**/*'
end
