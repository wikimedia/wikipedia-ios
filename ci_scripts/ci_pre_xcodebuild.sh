#!/bin/sh

# Stop running the script in case a command returns
# a nonzero exit code.
set -e

../scripts/setup_bundle_id ci # in case xcode cannot find a valid team id, this will set the default one

if [[ ${CI_WORKFLOW} == "Run Tests" ]]; then
    ./copy_sourceroot.sh
    echo "Execute copy source root."
    exit 0
fi

# Update CFBundleShortVersionString to a date-based version (YYYY.MM.DD).
DATE_VERSION=$(date -u "+%Y.%m.%d")
echo "Setting CFBundleShortVersionString to ${DATE_VERSION}"

PLISTS=(
    "../WMF Framework/Info.plist"
    "../Wikipedia Stickers/Info.plist"
    "../Wikipedia/Experimental-Info.plist"
    "../Wikipedia/Local-Info.plist"
    "../Wikipedia/Staging-Info.plist"
    "../Wikipedia/Wikipedia-Info.plist"
    "../ContinueReadingWidget/Info.plist"
    "../WikipediaUnitTests/Info.plist"
    "../Widgets/Info.plist"
    "../NotificationServiceExtension/Info.plist"
)

for PLIST in "${PLISTS[@]}"; do
    /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${DATE_VERSION}" "${PLIST}"
    echo "Updated ${PLIST}"
done

exit 0
