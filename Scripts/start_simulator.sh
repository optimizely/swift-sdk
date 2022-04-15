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
    sudo ln -s /Applications/$SIMULATOR_XCODE.app/Contents/Developer/Platforms/iPhoneOS.platform/Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE.simruntime /Library/Developer/CoreSimulator/Profiles/Runtimes/$OS_TYPE\ $OS.simruntime
fi

if [ "$SIMULATOR_XCODE" != 12.4 ]
then
    os="${OS/./-}"
    name="${NAME//./-}"
    xcrun simctl list runtimes
    xcrun simctl create "$NAME" "com.apple.CoreSimulator.SimDeviceType.$name" "com.apple.CoreSimulator.SimRuntime.$OS_TYPE-$os"
    xcrun simctl list devices $SIMULATOR_XCODE
fi

simulator=$( xcrun simctl list --json devices | jq -f /tmp/jq_file | jq -r '.[] | select(.name==env.NAME) | .udid' )
if [ -z $simulator ]; then
    echo "The requested simulator ($PLATFORM $OS $NAME) cannot be found."
    #xcrun instruments -s device
    xcrun xctrace list devices
    sleep 3
    exit 1
fi

xcrun simctl boot $simulator && sleep 30
xcrun simctl list | grep Booted
