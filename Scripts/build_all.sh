#!/bin/bash -e
################################################################
#    buildall.sh
################################################################
set -e

cleanup() {
  rm -f "${tempfiles[@]}"
}
trap cleanup 0

error() {
  local lineno="$1"
  local message="$2"
  local code="${3:-1}"
  if [[ -n "${message}" ]] ; then
    echo "Error on line ${lineno}: ${message}; status ${code}"
  else
    echo "Error on line ${lineno}; status ${code}"
  fi
  exit "${code}"
}
trap 'error ${LINENO}' ERR

main() {
  action="build"

  if [[ "$#" == "1" ]]; then
    # TODO: This isn't the best, but you can supply "clean" to our command.
    action="$1"
  fi;

  xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-iOS -configuration Release "${action}"
  xcodebuild -workspace OptimizelySwiftSDK.xcworkspace -scheme OptimizelySwiftSDK-tvOS -configuration Release "${action}"
}

main

