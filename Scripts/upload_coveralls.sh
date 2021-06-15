#!/bin/bash

# upload_coveralls.sh
#
# Usage:
#  $ ./upload_coveralls.sh
#

mkdir xccov2lcov && cd xccov2lcov && git init && git fetch --depth=1 https://github.com/trax-retail/xccov2lcov.git && git checkout FETCH_HEAD
xcrun xccov view --report --json ../$COVERAGE_DIR/Logs/Test/*.xcresult  > coverage.json
swift run xccov2lcov coverage.json > lcov.info

cd ..
coveralls-lcov -v --repo-token $COVERALLS_TOKEN   xccov2lcov/lcov.info
