#!/bin/bash -e
# Run the project test matrix against the simulators bundled with the selected Xcode image.

deviceModels=("iPhone 17" "iPad Pro 11-inch (M5)" "Apple TV 4K (3rd generation)")
osVersions=("27.0" "27.0" "27.0")
platforms=("iOS" "iOS" "tvOS")
testSdks=("iphonesimulator" "iphonesimulator" "appletvsimulator")

for i in "${!deviceModels[@]}"; do
  export PLATFORM="${platforms[$i]} Simulator"
  export OS="${osVersions[$i]}"
  export NAME="${deviceModels[$i]}"
  export OS_TYPE="${platforms[$i]}"
  echo "Testing OptimizelySwiftSDK-${platforms[$i]} (${deviceModels[$i]},OS=${osVersions[$i]})"
  
  xcrun xcodebuild -project OptimizelySwiftSDK.xcodeproj -scheme "OptimizelySwiftSDK-${platforms[$i]}" -sdk "${testSdks[$i]}" -configuration Release -destination "platform=${platforms[$i]} Simulator,name=${deviceModels[$i]},OS=${osVersions[$i]}" test
done
