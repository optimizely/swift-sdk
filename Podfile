workspace 'OptimizelySDK.xcworkspace'

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

target 'OptimizelySwiftSDK-iOS' do
  project 'OptimizelySwiftSDK.xcodeproj/'
  platform :ios, '9.0'
  use_frameworks!
  linter_pods
end

target 'OptimizelySwiftSDK-tvOS' do
  project 'OptimizelySwiftSDK.xcodeproj/'
  platform :tvos, '9.0'
  use_frameworks!
  linter_pods
end

target 'OptimizelyTests-Common-iOS' do
  project 'OptimizelySwiftSDK.xcodeproj/'
  platform :ios, '9.0'
  use_frameworks!
end

target 'OptimizelyTests-Common-tvOS' do
  project 'OptimizelySwiftSDK.xcodeproj/'
  platform :tvos, '9.0'
  use_frameworks!
end

target 'DemoSwiftiOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :ios, '9.0'
  use_frameworks!
  analytics_pods
  #pod 'OptimizelySwiftSDK','3.0.0'
end

target 'DemoSwifttvOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :tvos, '9.0'
  use_frameworks!
  #pod 'OptimizelySwiftSDK','3.0.0'
end

target 'DemoObjciOS' do
  project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
  platform :ios, '9.0'
  use_frameworks!
  analytics_pods
  #pod 'OptimizelySwiftSDK','3.0.0'
end

target 'DemoObjctvOS' do
  project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
  platform :tvos, '9.0'
  use_frameworks!
  #pod 'OptimizelySwiftSDK','3.0.0'
end

post_install do |installer|
        installer.pods_project.build_configurations.each do |config|
            config.build_settings.delete('CODE_SIGNING_ALLOWED')
            config.build_settings.delete('CODE_SIGNING_REQUIRED')
        end
        installer.pods_project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['SWIFT_VERSION'] = '4.2'
            end
        end
end
