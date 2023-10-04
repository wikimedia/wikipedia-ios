if [ $# -eq 0 ];
then
  echo "$0: Missing arguments"
  exit 1
elif [ $# -gt 3 ];
then
  echo "$0: Too many arguments: $@"
  exit 1
fi

EntitlementsFile=$1
InfoPListFile=$2
MerchantID=$3

echo "\n\n------Valid Parameters:------"

echo $EntitlementsFile
echo $InfoPListFile
echo $MerchantID

if [ ! -f "$EntitlementsFile" ]; then
    echo "Unable to find Entitlements file to update."
    exit 1
fi

if [ ! -f "$InfoPListFile" ]; then
    echo "Unable to find InfoPList file to update."
    exit 1
fi

if [ -z "$MerchantID" ]; then
    echo "MerchantID missing."
    exit 1
fi

echo "\n\n------Update MerchantID in Entitlements file------"

existingEntitlementsMerchantID=$(/usr/libexec/PlistBuddy -c "Print com.apple.developer.in-app-payments:0" "$EntitlementsFile")
echo "Existing EntitlementsFile MerchantID: $existingEntitlementsMerchantID"
if [ -z "$existingEntitlementsMerchantID" ]; then
    /usr/libexec/PlistBuddy -c "Add :com.apple.developer.in-app-payments: string '$MerchantID'" "$EntitlementsFile"
    newEntitlementsMerchantID=$(/usr/libexec/PlistBuddy -c "Print com.apple.developer.in-app-payments:0" "$EntitlementsFile")
    echo "Added EntitlementsFile MerchantID: $newEntitlementsMerchantID"
fi

echo "\n\n------Update MerchantID in Info.plist file------"

existingInfoPlistMerchantID=$(/usr/libexec/PlistBuddy -c "Print MerchantID" "$InfoPListFile")
echo "Existing InfoPListFile MerchantID: $existingInfoPlistMerchantID"
if [ -z "$existingInfoPlistMerchantID" ]; then
    /usr/libexec/PlistBuddy -c "Add MerchantID string '$MerchantID'" "$InfoPListFile"
    newInfoPlistMerchantID=$(/usr/libexec/PlistBuddy -c "Print MerchantID" "$InfoPListFile")
    echo "Added InfoPListFile MerchantID: $newInfoPlistMerchantID"
fi
