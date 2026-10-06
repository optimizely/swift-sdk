#!/bin/bash

# update_version.sh
#
# This script consistently updates the SDK version number in the SDK source.
#
# Usage:
#  $ ./update_version.sh [releaseSDKVersion]
#


#----------------------------------------------------------------------------------
# set the release SDK version
#----------------------------------------------------------------------------------
if [ "$#" -eq  "1" ];
then
    releaseSDKVersion="$1"
else
read  -p "Enter the new SDK release version (ex: 2.1.4): " releaseSDKVersion;
fi

varComps=( ${releaseSDKVersion//./ } )

if (( ${#varComps[@]} != 3 )); then
    printf "\n[ERROR] Invalid target version number: ${releaseSDKVersion} \n"
    exit 1
fi

cd "$(dirname $0)/.."

#----------------------------------------------------------------------------------
# 1. update the SDK version in SDKVersion.swift file
#----------------------------------------------------------------------------------
sdkVersionFilepath="Sources/Utils/SDKVersion.swift"
sdkVersionKey="OPTIMIZELYSDKVERSION"

printf "\tUpdating ${sdkVersionKey} to ${releaseSDKVersion}.\n"
sed -i '' -e "s/${sdkVersionKey}[ ]*=.*\"\(.*\)\"/${sdkVersionKey} = \"${releaseSDKVersion}\"/g" ${sdkVersionFilepath}

printf "Verifying ${sdkVersionKey} from ${sdkVersionFilepath}\n";
verifySdkVersion=$(sed -n "s/.*${sdkVersionKey} = \"\(.*\)\".*/\1/p" ${sdkVersionFilepath})

if [ "${verifySdkVersion}" == "${releaseSDKVersion}" ]
then
    printf "\tSDKVersion.swift file verified: ${releaseSDKVersion} === ${verifySdkVersion}\n"
else
    printf "\n[ERROR] SDKVersion.swift file has an error: [${verifySdkVersion}]";
    exit 1
fi


printf "\n\n[SUCCESS] All release-sdk-version settings have been updated successfully!\n\n\n"
