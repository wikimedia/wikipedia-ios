#!/bin/sh

# Stop running the script in case a command returns
# a nonzero exit code.
set -e

if [[ ${CI_WORKFLOW} == "Run Tests" ]]; then
    ./copy_sourceroot.sh
    echo "Execute copy source root."
    exit 0
fi

EntitlementsFile="${CI_PRIMARY_REPOSITORY_PATH}/Wikipedia/Wikipedia.entitlements"

if [[ ${CI_WORKFLOW} == "Weekly Staging Build" ]]; then
    InfoPListFile="${CI_PRIMARY_REPOSITORY_PATH}/Wikipedia/Staging-Info.plist"
    ./copy_environment_vars.sh $EntitlementsFile $InfoPListFile $MERCHANT_ID
    echo "Execute copy merchant IDs."
    exit 0
    
elif [[ ${CI_WORKFLOW} == "Nightly Build" ]]; then
    InfoPListFile="${CI_PRIMARY_REPOSITORY_PATH}/Wikipedia/Wikipedia-Info.plist"
    ./copy_environment_vars.sh $EntitlementsFile $InfoPListFile $MERCHANT_ID
fi

    

exit 0
