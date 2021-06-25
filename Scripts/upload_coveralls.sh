#!/bin/bash

# upload_coveralls.sh
#
# Usage:
#  $ ./upload_coveralls.sh
#

# [coveralls]
# - exclude coverage for Test codes by setting OptimizelySwiftSDK-iOS scheme > Test > Options > Gather coverage for selected targets
# - report coverage for PR and iPhone 11 only (avoid redundant ones)
# - use Xcode12.4+ (older Xcode reports a wrong number)
if [[ "$TRAVIS_BRANCH" == "master" && "$PLATFORM" == "iOS Simulator" && "$NAME" == "iPhone 11" ]]; then Scripts/upload_coveralls.sh; fi
        
mkdir xccov2lcov && cd xccov2lcov && git init && git fetch --depth=1 https://github.com/trax-retail/xccov2lcov.git && git checkout FETCH_HEAD
xcrun xccov view --report --json ../$COVERAGE_DIR/Logs/Test/*.xcresult  > coverage.json
swift run xccov2lcov coverage.json > lcov.info

cd ..
coveralls-lcov -v --repo-token $COVERALLS_TOKEN   xccov2lcov/lcov.info
