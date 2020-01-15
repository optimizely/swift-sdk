echo 'Testing OptimizelySwiftSDK-iOS (iPhone 8,OS=12.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 8,OS=12.1' test
echo 'Testing OptimizelySwiftSDK-iOS (iPhone SE,OS=11.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone SE,OS=11.1' test
echo 'Testing OptimizelySwiftSDK-iOS (iPhone XS,OS=13.2)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone XS,OS=13.2' test

echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV,OS=11.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV,OS=11.1' test
echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV,OS=12.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV,OS=12.1' test
echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV 4K,OS=13.2)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV 4K,OS=13.2' test
