#
# Be sure to run `pod lib lint DTAdsManager.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'DTAdsManager'
  s.version          = '0.1.1'
  s.summary          = 'A short description fffof DTAdsManager bs jkdhskj dkjsa kds kds sk.'
    s.swift_version = '4.0'
# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = 'Description'

  s.homepage         = 'https://github.com/pvddeveloper/DTAdsManager/tree/0.1.0'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Pham Diep' => 'pvddeveloper@gmail.com' }
  s.source           = { :git => 'https://github.com/pvddeveloper/DTAdsManager.git', :tag => s.version}
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'

  s.source_files = 'DTAdsManager/Classes/**/*'
  
  # s.resource_bundles = {
  #   'DTAdsManager' => ['DTAdsManager/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  s.static_framework = true
  s.dependency 'FBAudienceNetwork'
  s.dependency 'Google-Mobile-Ads-SDK'
end
