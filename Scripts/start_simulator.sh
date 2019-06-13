#!/bin/bash
set -eou pipefail

echo "PLATFORM: $PLATFORM OS: $OS NAME: $NAME"
xcrun simctl boot $(xcrun simctl list --json | jq '.devices."'"${PLATFORM% Simulator} $OS"'"' | jq -r '.[] | select(.name==env.NAME) | .udid')
xcrun simctl list | grep Booted
