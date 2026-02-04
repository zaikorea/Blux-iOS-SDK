#
# Be sure to run `pod lib lint BluxClient.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'BluxClient'
  s.version          = '0.6.9'
  s.summary          = 'Blux iOS SDK.'

  s.homepage         = 'https://github.com/zaikorea/Blux-iOS-SDK.git'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Blux' => 'tech@blux.ai' }

  s.source           = { :git => 'https://github.com/zaikorea/Blux-iOS-SDK.git', :tag => s.version.to_s }
  s.source_files = 'BluxClient/Classes/**/*'

  s.ios.deployment_target = '13.0'
  s.swift_version = '5.0'

  version = s.version.to_s

  # Android와 동일하게 "버전 이름"으로 stg/prod 배포를 구분합니다.
  #
  # stg 태그 형식:
  # - x.y.z-internal.N
  # - x.y.z-wip-name.N
  #
  # prod 태그 형식:
  # - x.y.z
  # - x.y.z-alpha.N
  # - x.y.z-beta.N
  # - x.y.z-rc.N
  is_stg = !!(version =~ /^\d+\.\d+\.\d+-(internal|wip-[a-z]+)\.[1-9]\d*$/)
  is_prod = !!(version =~ /^\d+\.\d+\.\d+(-((alpha|beta|rc)\.[1-9]\d*))?$/)

  swift_conditions = ['$(inherited)']
  if !is_stg && !is_prod
    raise <<~MSG
      Invalid pod version: '#{version}'

      Expected:
        stg:  x.y.z-internal.N, x.y.z-wip-name.N (name: [a-z]+, N: [1-9][0-9]*)
        prod: x.y.z, x.y.z-alpha.N, x.y.z-beta.N, x.y.z-rc.N (N: [1-9][0-9]*)
    MSG
  elsif is_stg
    swift_conditions += ['BLUX_STG']
  else
    # 고객사 영향 방지: 기본은 prod로 컴파일
    swift_conditions += ['BLUX_PROD']
  end

  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
    'SWIFT_ACTIVE_COMPILATION_CONDITIONS' => swift_conditions.join(' '),
  }
  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
