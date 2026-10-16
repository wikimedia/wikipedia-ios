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
    "../Wikipedia/Alpha-Info.plist"
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

# GitHub Actions is the primary deploy path; these Xcode Cloud workflows are
# the manual fallback for when it is unavailable, so the prefixes used when
# tagging have to stay in step with it - betas/ for production, alphas/ for
# Alpha, exp/ for design review.
#
# Xcode Cloud owns the build number. It keeps its own counter, exposed here as
# CI_BUILD_NUMBER, and that is what the archive ships with - so write that into
# the plist rather than deriving a number from the tag list. Nothing here reads
# existing tags: set the workflow's next build number in its Xcode Cloud
# settings before a fallback run, to one above the highest tag for its prefix.
if [[ ${CI_WORKFLOW} == "Beta Build" ]]; then
    BUILD_PLIST="../Wikipedia/Wikipedia-Info.plist"
elif [[ ${CI_WORKFLOW} == "Alpha Build" ]]; then
    BUILD_PLIST="../Wikipedia/Alpha-Info.plist"
elif [[ ${CI_WORKFLOW} == "Experimental Build" ]]; then
    BUILD_PLIST="../Wikipedia/Experimental-Info.plist"
else
    BUILD_PLIST=""
fi

if [[ -n "${BUILD_PLIST}" ]]; then
    if [[ -z "${CI_BUILD_NUMBER}" ]]; then
        echo "CI_BUILD_NUMBER is empty - cannot set a build number"
        exit 1
    fi
    echo "Setting CFBundleVersion to ${CI_BUILD_NUMBER}"
    /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${CI_BUILD_NUMBER}" "${BUILD_PLIST}"
fi

exit 0
