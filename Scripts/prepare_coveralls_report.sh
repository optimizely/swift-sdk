#!/bin/bash -e

# prepare_coveralls_report.sh
#
# Usage:
#  $ ./prepare_coveralls_report.sh
#

# [coveralls]
# - test targets compile the SDK sources themselves, so the scheme gathers coverage for all targets
#   (xccov merges per source file) and only Optimizely.framework is exported, excluding Test codes
mkdir xccov2lcov && cd xccov2lcov && git init && git fetch --depth=1 https://github.com/trax-retail/xccov2lcov.git fd0b15537f0b4b949d8e6b8a38eeef09a35d31ff && git checkout FETCH_HEAD
xcrun xccov view --report --json ../$COVERAGE_DIR/Logs/Test/*.xcresult  > coverage.json
swift run xccov2lcov coverage.json --include-target Optimizely.framework > lcov.info
cd ..
