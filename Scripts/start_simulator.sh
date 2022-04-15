#!/usr/bin/env bash
set -eou pipefail

# expects the following environment variables defined
# PLATFORM (eg. iOS Simulator)
# OS (eg. 12.0)
# NAME (eg. iPad Air)

# prep jq arg because it doesnt allow parameter expansion within its single quotes
echo ".devices.\"com.apple.CoreSimulator.SimRuntime.${PLATFORM/ Simulator/}-${OS/./-}\"" > /tmp/jq_file
sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes
if [ "$SIMULATOR_XCODE" == 10.3 ]
then
    sudo ln -s /Applications/Xcode_10.3.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/$OS_TYPE.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE\ $OS.simruntime
elif [ "$SIMULATOR_XCODE" != 12.4 ]; then 
    sudo ln -s /Applications/Xcode_$SIMULATOR_XCODE.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE\ $OS.simruntime
fi

if [ "$SIMULATOR_XCODE" != 12.4 ]
then
    os="${OS/./-}"
    name="${NAME// /-}"
    if [ "$name" == "Apple-TV-4K" ]
    then
        name="${name}-1080p"
    fi
    
    xcrun simctl create "custom-device" "com.apple.CoreSimulator.SimDeviceType.$name" "com.apple.CoreSimulator.SimRuntime.$OS_TYPE-$os"
    CUSTOM_SIMULATOR="$(instruments -s devices | grep -m 1 'custom-device' | awk -F'[][]' '{print $2}')"
else
    CUSTOM_SIMULATOR="$(instruments -s devices | grep -m 1 '$NAME' | awk -F'[][]' '{print $2}')"
fi

xcrun simctl list runtimes
xcrun simctl boot $CUSTOM_SIMULATOR && sleep 30
xcrun simctl list | grep Booted
