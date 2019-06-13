#!/usr/bin/env bash
set -eou pipefail

# expects the following environment variables defined
# PLATFORM (eg. iOS Simulator)
# OS (eg. 12.0)
# NAME (eg. iPad Air)

# prep jq arg because it doesnt allow parameter expansion within its single quotes
echo ".devices.\"com.apple.CoreSimulator.SimRuntime.${PLATFORM/ Simulator/}-${OS/./-}\"" > /tmp/jq_file

xcrun simctl boot $( xcrun simctl list --json devices | jq -f /tmp/jq_file | jq -r '.[] | select(.name==env.NAME) | .udid' ) && sleep 30
xcrun simctl list | grep Booted
