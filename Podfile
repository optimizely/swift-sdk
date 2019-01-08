workspace 'OptimizelySDK.xcworkspace'


def analytics_pods
    pod 'Amplitude-iOS'
    pod 'Google/Analytics'
    pod 'Localytics'
    pod 'Mixpanel-swift'
end

use_frameworks!

# DemoSwiftiOS target
target 'DemoSwiftiOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :ios, '8.0'
  use_frameworks!
  analytics_pods
  
  pod 'OptimizelySDKiOS', '2.1.4'
end

# DemoSwifttvOS target
target 'DemoSwifttvOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :tvos, '9.0'
  
  pod 'OptimizelySDKTVOS', '2.1.4'
end

# DemoObjciOS target
target 'DemoObjciOS' do
    project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
    platform :ios, '8.0'
    use_frameworks!
    analytics_pods
    
    pod 'OptimizelySDKiOS', '2.1.4'
end

# DemoObjctvOS target
target 'DemoObjctvOS' do
    project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
    platform :tvos, '9.0'
    
    pod 'OptimizelySDKTVOS', '2.1.4'
end
