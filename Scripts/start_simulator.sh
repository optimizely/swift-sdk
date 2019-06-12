#!/bin/bash
set -eou pipefail 
echo "PLATFORM: $PLATFORM OS: $OS NAME: $NAME"
xcrun simctl boot $(xcrun simctl list --json | jq '.devices."'"$(echo $PLATFORM | awk '{print $1}') $OS"'"' | jq -r '.[] | select(.name==env.NAME) | .udid')
