#!/bin/sh

# Stop running the script in case a command returns
# a nonzero exit code.
set -e

if [[ ${CI_WORKFLOW} == "Run Tests" ]]; then
	./copy_sourceroot.sh
	echo "Execute copy source root."
	exit 0
fi

EntitlementsFile="${CI_WORKSPACE}/Wikipedia/Wikipedia.entitlements"

if [[ ${CI_WORKFLOW} == "Weekly Staging Build" ]]; then
    InfoPListFile="${CI_WORKSPACE}/Wikipedia/Staging-Info.plist"
    ./copy_environment_vars.sh EntitlementsFile InfoPListFile $MERCHANT_ID $PAYMENTS_API_KEY
    echo "Execute copy merchant IDs."
    exit 0
    
elif [[ ${CI_WORKFLOW} == "Nightly Build" ]]; then
    InfoPListFile="${CI_WORKSPACE}/Wikipedia/Wikipedia-Info.plist"
    ./copy_environment_vars.sh EntitlementsFile InfoPListFile $MERCHANT_ID $PAYMENTS_API_KEY
fi

    

exit 0
