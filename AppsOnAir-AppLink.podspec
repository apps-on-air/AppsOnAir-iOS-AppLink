#
# Be sure to run `pod lib lint AppsOnAir-AppLink.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|

  s.name             = 'AppsOnAir-AppLink'
  s.version          = '0.0.3'
  s.summary          = 'AppsOnAir-AppLink'
  s.description      = "A self-hosted dynamic link service for app download tracking, deep linking, and engagement analytics for ios - an alternative to Firebase Dynamic Links"
  s.homepage         = 'https://documentation.appsonair.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'devtools-logicwind' => 'devtools@logicwind.com' }
  s.source           = { :git => 'https://github.com/apps-on-air/AppsOnAir-iOS-AppLink.git', :tag => s.version.to_s }

  s.swift_version  = '5.0'
  s.ios.deployment_target = '13.0'
  
  # AppsOnAir Core pod
  s.dependency 'AppsOnAir-Core', '0.0.4'
  
  s.vendored_frameworks = 'AppsOnAir_AppLink.xcframework'
  
end
