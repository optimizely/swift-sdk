workspace 'OptimizelySDK.xcworkspace'


def analytics_pods
    pod 'Amplitude-iOS'
    pod 'Google/Analytics'
    pod 'Localytics'
    pod 'Mixpanel-swift'
end

use_frameworks!

# OptimizelyiOSDemoApp target
target 'OptimizelyiOSDemoApp' do
  project 'OptimizelyDemoApp/OptimizelyDemoApp.xcodeproj/'
  platform :ios, '8.0'
  use_frameworks!
  analytics_pods
  
  pod 'OptimizelySDKiOS', '2.1.4'
end

# OptimizelyTVOSDemoApp target
target 'OptimizelyTVOSDemoApp' do
  project 'OptimizelyDemoApp/OptimizelyDemoApp.xcodeproj/'
  platform :tvos, '9.0'
  
  pod 'OptimizelySDKTVOS', '2.1.4'
end
