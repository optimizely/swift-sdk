echo 'Testing OptimizelySwiftSDK-iOS (iPhone 6,OS=9.2)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 6,OS=9.0' test
echo 'Testing OptimizelySwiftSDK-iOS (iPhone 8,OS=12.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone 8,OS=12.1' test
echo 'Testing OptimizelySwiftSDK-iOS (iPhone SE,OS=10.0)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone SE,OS=10.0' test
echo 'Testing OptimizelySwiftSDK-iOS (iPhone XS,OS=12.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -sdk iphonesimulator -destination 'platform=iOS Simulator,name=iPhone XS,OS=12.1' test

echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV 1080p,OS=9.0)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV 1080p,OS=9.0' test
echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV,OS=11.0)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV,OS=11.0' test
echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV,OS=12.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV,OS=12.1' test
echo 'Testing OptimizelySwiftSDK-tvOS (Apple TV 4K,OS=12.1)'
xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -sdk appletvsimulator -destination 'platform=tvOS Simulator,name=Apple TV 4K,OS=12.1' test
