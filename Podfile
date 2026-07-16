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
  pod 'SwiftLint', '0.43.1'
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

# Disable Code Coverage for Pods projects
post_install do |installer_representation|
    installer_representation.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_ENABLE_CODE_COVERAGE'] = 'NO'
        end
    end
end


