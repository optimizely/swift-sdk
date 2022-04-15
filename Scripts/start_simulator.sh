#!/usr/bin/env bash
set -eou pipefail

# expects the following environment variables defined
# SIMULATOR_XCODE (Which Xcode's simulator to use)
# OS (eg. 12.0)
# NAME (eg. iPad Air)
# OS_TYPE (eg. iOS)
# More about XCode and its compatible simulators can be found here: https://github.com/actions/virtual-environments/blob/main/images/macos/macos-10.15-Readme.md
sudo mkdir -p /Library/Developer/CoreSimulator/Profiles/Runtimes

if [ $SIMULATOR_XCODE != 12.4 ]; then

    os_folder="iPhoneOS"
    os="${OS/./-}"
    name="${NAME// /-}"

    # Check if device is Apple tv, update os_folder for linking purposes
    if [ $NAME == "Apple TV 4K" ]
    then
        name="${name}-4K"
        os_folder="AppleTVOS"
    fi

    # update os_folder as per xcode version
    if [ $SIMULATOR_XCODE == 10.3 ]
    then
        os_folder="${os_folder}.platform/Developer/Library"
    else
        os_folder="${os_folder}.platform/Library/Developer"
    fi

    # Create link and create simulators which are not part of the current xcode version
    sudo ln -s /Applications/Xcode_$SIMULATOR_XCODE.app/Contents/Developer/Platforms/$os_folder/CoreSimulator/Profiles/Runtimes/$OS_TYPE.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE\ $OS.simruntime
    xcrun simctl create "custom-device" "com.apple.CoreSimulator.SimDeviceType.$name" "com.apple.CoreSimulator.SimRuntime.$OS_TYPE-$os"
    CUSTOM_SIMULATOR="$(instruments -s devices | grep -m 1 'custom-device' | awk -F'[][]' '{print $2}')"
else
    CUSTOM_SIMULATOR=$( xcrun simctl list --json devices | jq -f /tmp/jq_file | jq -r '.[] | select(.name==env.NAME) | .udid' )
fi

xcrun simctl boot $CUSTOM_SIMULATOR && sleep 30
