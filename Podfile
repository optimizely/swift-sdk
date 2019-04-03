workspace 'OptimizelySDK.xcworkspace'


def analytics_pods
    pod 'Amplitude-iOS'
    pod 'Google/Analytics'
    pod 'Localytics'
    pod 'Mixpanel-swift', '2.5.7'
end

use_frameworks!

# OptimizelyTests-Common-iOS target
target 'OptimizelyTests-Common-iOS' do
  project 'OptimizelySDK/OptimizelySwiftSDK.xcodeproj/'
  platform :ios, '10.0'
  use_frameworks!
  pod 'SwiftyJSON', '4.0'
  
  # use local SDK framework
  #pod 'OptimizelySwiftSDK', :path => '.'
end

# OptimizelyTests-Common-tvOS target
target 'OptimizelyTests-Common-tvOS' do
  project 'OptimizelySDK/OptimizelySwiftSDK.xcodeproj/'
  platform :tvos, '10.0'
  use_frameworks!
  pod 'SwiftyJSON', '4.0'
  
  # use local SDK framework
  #pod 'OptimizelySwiftSDK', :path => '.'
end

# DemoSwiftiOS target
target 'DemoSwiftiOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :ios, '10.0'
  use_frameworks!
  analytics_pods
  
  # use local SDK framework
  #pod 'OptimizelySwiftSDK', :path => '.'
end

# DemoSwifttvOS target
target 'DemoSwifttvOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :tvos, '10.0'
  
  # use local SDK framework
  #pod 'OptimizelySwiftSDK', :path => '.'
end

# DemoObjciOS target
target 'DemoObjciOS' do
    project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
    platform :ios, '10.0'
    use_frameworks!
    analytics_pods
    
    ##pod 'OptimizelySDKiOS', '2.1.4'
end

# DemoObjctvOS target
target 'DemoObjctvOS' do
    project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
    platform :tvos, '10.0'
    
    ##pod 'OptimizelySDKTVOS', '2.1.4'
end
