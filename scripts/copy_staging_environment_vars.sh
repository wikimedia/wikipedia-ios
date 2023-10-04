# This mimics the script that Xcode Cloud will call for the Staging and Production builds. It will pass in the proper environment variable parameters to copy_environment_vars.sh (see ci-scripts/ci_pre_xcodebuild.sh).
# Use this script for locally populating the entitlements and Info.plist files with Merchant IDs, API Keys, etc.
# From root directory, call with:
# ./scripts/copy_staging_environment_vars.sh "{merchant-ID-here}"
# Do not commit the changes this script causes.

if [ $# -eq 0 ];
then
  echo "$0: Missing arguments"
  exit 1
elif [ $# -gt 2 ];
then
  echo "$0: Too many arguments: $@"
  exit 1
fi

EntitlementsFile="Wikipedia/Wikipedia.entitlements"
InfoPListFile="Wikipedia/Staging-Info.plist"
MerchantID=$1

./ci_scripts/copy_environment_vars.sh $EntitlementsFile $InfoPListFile $MerchantID
