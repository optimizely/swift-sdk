#!/bin/bash

# update_version.sh
#
# This script consistently updates the SDK version numbers in several places:
# 1. {XcodeProject}/{XcodeProject}.xcodeproj/project.pbxproj
# 2. {XcodeProject}.podspec
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

vMajor=${varComps[0]}
vMinor=${varComps[1]}
vPatch=${varComps[2]}
vSuffix=""

if [[ $vPatch =~ ^([0-9]+)([^0-9]*)$ ]] ; then
    vPatch=${BASH_REMATCH[1]}
    vSuffix=${BASH_REMATCH[2]}
fi

printf "\nRelease SDK Version: ${vMajor}.${vMinor}.${vPatch}${vSuffix} \n"

cd "$(dirname $0)/.."

#----------------------------------------------------------------------------------
# 1. update the SDK version in all xcode project settings
#----------------------------------------------------------------------------------
printf "\n\nReplacing OPTIMIZELY_SDK_VERSION in Xcode Build Settings to the target version.\n"

curPbxProjPath="OptimizelySDK/OptimizelySwiftSDK.xcodeproj/project.pbxproj"
printf "\t[Updating .pbxproj to ${releaseSDKVersion}.\n"

sed -i '' -e "s/\(OPTIMIZELY_SDK_VERSION_MAJOR[ ]*\)=.*;/\1= \"${vMajor}\";/g" ${curPbxProjPath}
sed -i '' -e "s/\(OPTIMIZELY_SDK_VERSION_MINOR[ ]*\)=.*;/\1= \"${vMinor}\";/g" ${curPbxProjPath}
sed -i '' -e "s/\(OPTIMIZELY_SDK_VERSION_PATCH[ ]*\)=.*;/\1= \"${vPatch}\";/g" ${curPbxProjPath}
sed -i '' -e "s/\(OPTIMIZELY_SDK_VERSION_SUFFIX[ ]*\)=.*;/\1= \"${vSuffix}\";/g" ${curPbxProjPath}

printf "Verifying OPTIMIZELY_SDK_VERSION from Xcode Build Settings.\n";

curProjPath="OptimizelySDK/OptimizelySwiftSDK.xcodeproj"

OPTIMIZELY_SDK_VERSION=$(Xcodebuild -project ${curProjPath} -showBuildSettings | sed -n 's/OPTIMIZELY_SDK_VERSION = \(.*\)/\1/p' | sed 's/ //g');

if [ "${OPTIMIZELY_SDK_VERSION}" == "${releaseSDKVersion}" ]
then
    printf "\t[OPTIMIZELY_SDK_VERSION in xcode settings verified: ${releaseSDKVersion} === ${OPTIMIZELY_SDK_VERSION}\n"
else
    printf "\n[ERROR][${curMod}] OPTIMIZELY_SDK_VERSION mismatch: (releaseSDKVersion/OPTIMIZELY_SDK_VERSION) = ${releaseSDKVersion}/${OPTIMIZELY_SDK_VERSION}\n";
    exit 1
fi


#----------------------------------------------------------------------------------
# 2. update the SDK version in all podspecs
#----------------------------------------------------------------------------------
printf "\n\nReplacing all versions in *.podspec files\n"

curPodSpec="OptimizelySwiftSDK.podspec"

printf "\t[${curPodSpec}] Updating podspec to ${releaseSDKVersion}.\n"
sed -i '' -e "s/\(s\.version[ ]*\)=[ ]*\".*\"/\1= \"${releaseSDKVersion}\"/g" ${curPodSpec}

# pod-spec-lint cannot be run here due to dependency issues
# all podspecs will be validated anyway when uploading to CocoaPods repo

printf "Verifying *.podspec files\n"

vm=$(sed -n "s/s\.version.*=.*\"\(.*\)\"/\1/p" ${curPodSpec} | sed "s/ //g" )
if [ "${vm}" == "${releaseSDKVersion}" ]; then
    printf "\t[${curPodSpec}] Verified podspec: ${vm} === ${releaseSDKVersion}\n"
fi

printf "\n\n[SUCCESS] All release-skd-version settings have been updated successfully!\n\n\n"
