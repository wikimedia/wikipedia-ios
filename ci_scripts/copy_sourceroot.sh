#!/bin/sh
 
# Stop running the script in case a command returns
# a nonzero exit code.
set -e
 
if [[ ${CI_XCODEBUILD_ACTION} == "build-for-testing" ]]; then
    cd ../WikipediaUnitTests/
    SOURCEROOT="${CI_PRIMARY_REPOSITORY_PATH}/ci_scripts"
    plutil -replace SOURCE_ROOT_DIR -string $SOURCEROOT Info.plist
    plutil -p Info.plist
    echo "CI_WORKSPACE value successfully copied into Info.plist SOURCE_ROOT_DIR key."
    exit 0
else
    echo "Did not execute copy source root."
    exit 0
fi
