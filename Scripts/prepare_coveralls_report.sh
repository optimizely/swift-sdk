#!/bin/bash -e

# prepare_coveralls_report.sh
#
# Usage:
#  $ ./prepare_coveralls_report.sh
#

# [coveralls]
# - exclude coverage for Test codes by setting OptimizelySwiftSDK-iOS scheme > Test > Options > Gather coverage for selected targets
mkdir xccov2lcov && cd xccov2lcov && git init && git fetch --depth=1 https://github.com/trax-retail/xccov2lcov.git fd0b15537f0b4b949d8e6b8a38eeef09a35d31ff && git checkout FETCH_HEAD
xcrun xccov view --report --json ../$COVERAGE_DIR/Logs/Test/*.xcresult  > coverage.json
swift run xccov2lcov coverage.json > lcov.info
cd ..
