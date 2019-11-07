#!/usr/bin/env bash
set -eou pipefail

# expects the following environment variables defined
# PLATFORM (eg. iOS Simulator)
# OS (eg. 12.0)
# NAME (eg. iPad Air)

# prep jq arg because it doesnt allow parameter expansion within its single quotes
vs=( ${OS//./ } )                   # replace points, split into array
version="${vs[0]}-${vs[1]}"         # truncate minor version of iOS (simctl list does not differentiate minor versions: 10.3.1 -> 10-3)
echo ".devices.\"com.apple.CoreSimulator.SimRuntime.${PLATFORM/ Simulator/}-${version}\"" > /tmp/jq_file

# print out all available simulator versions in travis xcode
#xcrun simctl list

xcrun simctl boot $( xcrun simctl list --json devices | jq -f /tmp/jq_file | jq -r '.[] | select(.name==env.NAME) | .udid' ) && sleep 30
xcrun simctl list | grep Booted
