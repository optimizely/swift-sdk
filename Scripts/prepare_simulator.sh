#!/usr/bin/env bash
set -eou pipefail

# expects the following environment variables defined
# PLATFORM (eg. iOS Simulator)
# OS (eg. 12.0)
# NAME (eg. iPad Air)
# OS_TYPE (eg. iOS)
# SIMULATOR_XCODE_VERSION (Which Xcode's simulator to use)
# Since github actions only provide limit simulators with each xcode, we need to link simulators from other versions of xcode to be used by current xcode.
# We must use old simulators with current xcode since old xcode doesnot support swift 5 required by Swift SDK. 
# More about XCode and its compatible simulators can be found here: https://github.com/actions/virtual-environments/blob/main/images/macos/macos-10.15-Readme.md

if [ "$SIMULATOR_XCODE_VERSION" != 12.4 ]; then
    os_folder="iPhoneOS"
    os="${OS/./-}"
    name="${NAME// /-}"

    sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes

    # Check if device is Apple tv, update os_folder for linking purposes
    if [ "$NAME" == "Apple TV 4K" ]
    then
        name="${name}-4K"
        os_folder="AppleTVOS"
    fi

    # update os_folder as per xcode version
    if [ "$SIMULATOR_XCODE_VERSION" == 10.3 ]
    then
        os_folder="${os_folder}.platform/Developer/Library"
    else
        os_folder="${os_folder}.platform/Library/Developer"
    fi

    # Link and create simulators from older xcode versions which are not part of the current xcode version
    sudo ln -s /Applications/Xcode_$SIMULATOR_XCODE_VERSION.app/Contents/Developer/Platforms/$os_folder/CoreSimulator/Profiles/Runtimes/$OS_TYPE.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE\ $OS.simruntime
    xcrun simctl create "custom-device" "com.apple.CoreSimulator.SimDeviceType.$name" "com.apple.CoreSimulator.SimRuntime.$OS_TYPE-$os"
    UDID="$(instruments -s devices | grep -m 1 'custom-device' | awk -F'[][]' '{print $2}')"
else
    echo ".devices.\"com.apple.CoreSimulator.SimRuntime.${PLATFORM/ Simulator/}-${OS/./-}\"" > /tmp/jq_file
    UDID=$( xcrun simctl list --json devices | jq -f /tmp/jq_file | jq -r '.[] | select(.name==env.NAME) | .udid' )
fi

echo "$UDID"
