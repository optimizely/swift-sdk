#!/bin/bash
if [ $# != 1 ]; then
    echo "Usage: replace_headers_folder.sh <folder>"
    exit 1
fi

SCRIPT_DIR=`dirname $0`
ROOT_DIR="${PWD}/$1"

# do no break spaces in file names
IFS=$'\n'

pushd $SCRIPT_DIR > /dev/null

for f in $(find $ROOT_DIR -name '*.swift' -or -name '*.h' -or -name '*.m')
do
    if [[ "$f" == *"Pods/"* ]] ; then
        continue
    fi

    echo "replacing header for: $f"
    replace_header.sh "$f"
done

popd > /dev/null
