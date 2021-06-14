#!/bin/bash

# upload_coveralls.sh
#
# Usage:
#  $ ./upload_coveralls.sh
#

git clone git@github.com:trax-retail/xccov2lcov.git
cd xccov2lcov

xcrun xccov view --report --json ../$COVERAGE_DIR/Logs/Test/*.xcresult  > cov.json
swift run xccov2lcov coverage.json > lcov.info

cd ..
coveralls-lcov -v --repo-token $COVERALLS_TOKEN   xccov2lcov/lcov.info
