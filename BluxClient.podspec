#
# Be sure to run `pod lib lint BluxClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BluxClient'
  s.version          = '0.5.3'
  s.summary          = 'Blux iOS SDK.'

  s.homepage         = 'https://github.com/zaikorea/Blux-iOS-SDK.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Blux' => 'tech@blux.ai' }

  s.source           = { :git => 'https://github.com/zaikorea/Blux-iOS-SDK.git', :tag => s.version.to_s }
  s.source_files = 'BluxClient/Classes/**/*'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
