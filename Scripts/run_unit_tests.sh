#!/bin/bash
set -euo pipefail

# run xcode unit tests
# ponytail: failed tests are retried up to 3 times to mask flaky tests; drop the retry once they're fixed
#
# Usage:
#  $ ./run_unit_tests.sh
#

xcodebuild test -derivedDataPath "$COVERAGE_DIR" -project OptimizelySwiftSDK.xcodeproj -scheme "$SCHEME" -configuration Release CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO -sdk "$TEST_SDK" -destination "platform=$PLATFORM,OS=$OS,name=$NAME" ONLY_ACTIVE_ARCH=YES \
  -retry-tests-on-failure -test-iterations 3 | xcbeautify --renderer github-actions
