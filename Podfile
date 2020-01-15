workspace 'OptimizelySwiftSDK.xcworkspace'

def analytics_pods
#  pod 'Amplitude-iOS'
#  pod 'Google/Analytics'
#  pod 'Localytics'
#  pod 'Mixpanel-swift', '2.5.7'
end

def linter_pods
  # ignore all warnings from all dependencies
  inhibit_all_warnings!
  pod 'SwiftLint'
end

target 'DemoSwiftiOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :ios, '10.0'
  use_frameworks!
  analytics_pods
  linter_pods
  #pod 'OptimizelySwiftSDK','3.0.0'
end

target 'DemoSwifttvOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :tvos, '10.0'
  use_frameworks!
  linter_pods
  #pod 'OptimizelySwiftSDK','3.0.0'
end

target 'DemoObjciOS' do
  project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
  platform :ios, '10.0'
  use_frameworks!
  analytics_pods
  #pod 'OptimizelySwiftSDK','3.0.0'
end

target 'DemoObjctvOS' do
  project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
  platform :tvos, '10.0'
  use_frameworks!
  #pod 'OptimizelySwiftSDK','3.0.0'
end
