
#!/bin/bash -e
# Since github actions only provides limit simulators with each xcode, we need to link simulators from other versions of xcode to be used by current xcode.
# We must use old simulators with current xcode since older xcode versions do not support swift 5 which is required by Swift SDK. 
# More about XCode and its compatible simulators can be found here: https://github.com/actions/virtual-environments/blob/main/images/macos/macos-10.15-Readme.md
# https://github.com/actions/virtual-environments/issues/551

deviceModels=("iPhone 12" "iPhone 8" "iPad Air (4th generation)" "Apple TV")
osVersions=("16.0" "14.4" "15.0" "16.0")
xcodeVersions=("14.3" "14.3" "14.3" "14.3")
platforms=("iOS" "iOS" "iOS" "tvOS")
testSdks=("iphonesimulator" "iphonesimulator" "iphonesimulator" "appletvsimulator")

for i in "${!deviceModels[@]}"; do
  export PLATFORM="${platforms[$i]} Simulator"
  export OS="${osVersions[$i]}"
  export NAME="${deviceModels[$i]}"
  export OS_TYPE="${platforms[$i]}"
  export SIMULATOR_XCODE_VERSION="${xcodeVersions[$i]}"
  
  Scripts/prepare_simulator.sh
  echo "Testing OptimizelySwiftSDK-${platforms[$i]} (${deviceModels[$i]},OS=${osVersions[$i]})"
  
  xcrun xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme "OptimizelySwiftSDK-${platforms[$i]}" -sdk "${testSdks[$i]}" -configuration Release -destination "platform=${platforms[$i]} Simulator,name=${deviceModels[$i]},OS=${osVersions[$i]}" test
done
