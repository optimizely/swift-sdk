workspace 'OptimizelySDK.xcworkspace'

def common_pods
  pod 'SwiftyJSON', '4.0'
end

target 'OptimizelyTests-Common-iOS' do
  project 'OptimizelySDK/OptimizelySwiftSDK.xcodeproj/'
  platform :ios, '10.0'
  common_pods
end

target 'OptimizelyTests-Common-tvOS' do
  project 'OptimizelySDK/OptimizelySwiftSDK.xcodeproj/'
  platform :tvos, '10.0'
  common_pods
end

target 'DemoSwiftiOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :ios, '10.0'
end

target 'DemoSwifttvOS' do
  project 'DemoSwiftApp/DemoSwiftApp.xcodeproj/'
  platform :tvos, '10.0'
end

target 'DemoObjciOS' do
  project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
  platform :ios, '10.0'
end

target 'DemoObjctvOS' do
  project 'DemoObjcApp/DemoObjcApp.xcodeproj/'
  platform :tvos, '10.0'
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
