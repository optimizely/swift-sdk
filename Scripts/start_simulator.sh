#!/bin/bash

# start_simulator.sh
#
# Usage:
#  $ ./start_simulator.sh <simulator-device-type> <simulator-device-os>
#
# Samples:
#  $ start_simulator.sh com.apple.CoreSimulator.SimDeviceType.iPad-Air com.apple.CoreSimulator.SimRuntime.iOS-9-3
#  $ start_simulator.sh com.apple.CoreSimulator.SimDeviceType.iPhone-7-Plus com.apple.CoreSimulator.SimRuntime.iOS-11-4
#  $ start_simulator.sh com.apple.CoreSimulator.SimDeviceType.iPhone-7 com.apple.CoreSimulator.SimRuntime.iOS-12-1
#  $ start_simulator.sh com.apple.CoreSimulator.SimDeviceType.Apple-TV-4K-4K com.apple.CoreSimulator.SimRuntime.tvOS-12-1
#
# To get lists of simulator Device-Types and Runtimes:
#  $ xcrun simctl list


#----------------------------------------------------------------------------------
# set the release SDK version
#----------------------------------------------------------------------------------
if [ "$#" -eq  "2" ];
then
    deviceType="$1"
    deviceOS="$2"
else
    printf "\n[ERROR] Enter device-type and os-version \n"
    exit 1
fi

cd "$(dirname $0)/.."

# close all simulators currently open
xcrun simctl shutdown all

# grep simulator UUID
deviceUUID="$( xcrun simctl create TestSimulator $deviceType $deviceOS )"

# start simulator with UUID
if [ $? -eq 0 ]
then
    xcrun simctl boot $deviceUUID
else
    printf "\n[ERROR] Invalid simulator type or version \n"
    exit 1
fi
