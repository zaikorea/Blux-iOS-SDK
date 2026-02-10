#
# Be sure to run `pod lib lint BluxClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BluxClient'
  s.version          = '0.6.11'
  s.summary          = 'Blux iOS SDK.'

  s.homepage         = 'https://github.com/zaikorea/Blux-iOS-SDK.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Blux' => 'tech@blux.ai' }

  s.source           = { :git => 'https://github.com/zaikorea/Blux-iOS-SDK.git', :tag => s.version.to_s }
  s.source_files = 'BluxClient/Classes/**/*'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  # Stage 설정: 환경변수 BLUX_STAGE (기본값: prod)
  # 배포 시 scripts/publish.sh에서 자동 설정됨
  stage = (ENV['BLUX_STAGE'] || 'prod').downcase
  swift_flags = stage == 'prod' ? '' : "-D BLUX_#{stage.upcase} -D ENABLE_STAGE_SWITCHING"

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'OTHER_SWIFT_FLAGS' => "$(inherited) #{swift_flags}".strip,
    'SWIFT_VERSION' => '5.0',
  }
end
