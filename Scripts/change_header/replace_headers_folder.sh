#!/bin/bash
SCRIPT_DIR=`dirname $0`
if [ $# != 1 ]; then
    echo "Usage: replace_headers_folder.sh <folder>"
    exit 1
fi

ROOT_DIR="${PWD}/$1"

# do no break spaces in file names
IFS=$'\n'

for f in $(find $ROOT_DIR -name '*.swift' -or -name '*.h' -or -name '*.m')
do
    if [[ "$f" == *"Pods/"* ]] ; then
        continue
    fi

    pushd $SCRIPT_DIR > /dev/null
    echo "replacing header for: $f"
    replace_header.sh "$f"
    popd > /dev/null
done

