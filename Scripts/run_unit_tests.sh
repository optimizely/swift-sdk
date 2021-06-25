#!/bin/bash

# run xcode unit tests
#
# Usage:
#  $ ./run_unit_tests.sh
#

# unit tests for PR only
if [[ "$TRAVIS_BRANCH" == "master" ]]
then
  xcodebuild test -derivedDataPath $COVERAGE_DIR  -workspace OptimizelySwiftSDK.xcworkspace -scheme $SCHEME -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -sdk $TEST_SDK -destination "platform=$PLATFORM,OS=$OS,name=$NAME" ONLY_ACTIVE_ARCH=YES | tee buildoutput | xcpretty && test ${PIPESTATUS[0]} -eq 0
fi
