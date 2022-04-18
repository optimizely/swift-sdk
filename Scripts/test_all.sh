deviceModels=("iPhone SE" "iPhone 8" "iPhone 11", "Apple TV" "Apple TV" "Apple TV 4K")
osVersions=("12.4" "13.3" "14.4", "12.4", "13.3", "14.3")
xcodeVersions=("10.3" "11.3.1" "12.4", "10.3", "11.3.1", "12.4")
platforms=("iOS" "iOS" "iOS", "tvOS", "tvOS", "tvOS")
testSdks=("iphonesimulator" "iphonesimulator" "iphonesimulator", "appletvsimulator", "appletvsimulator", "appletvsimulator")

for i in ${!deviceModels[@]}; do
  PLATFORM="${platforms[$i]} Simulator"
  OS="${osVersions[$i]}"
  NAME="${deviceModels[$i]}"
  OS_TYPE="${platforms[$i]}"
  SIMULATOR_XCODE_VERSION="${xcodeVersions[$i]}"
  Scripts/prepare_simulator.sh
  echo "Testing OptimizelySwiftSDK-${platforms[$i]} (${deviceModels[$i]},OS=${osVersions[$i]})"
  xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme "OptimizelySwiftSDK-${platforms[$i]}" -sdk "${testSdks[$i]}" -destination "platform=${platforms[$i]} Simulator,name=${deviceModels[$i]},OS=${osVersions[$i]}" test
done