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

# TODO: GitHub Actions is the primary deploy path now - version naming,
# build numbering and tagging all happen there (v2_deploy_design_review,
# v2_deploy_alpha, v2_deploy_beta, v2_submit_appstore). Xcode Cloud stays
# available as a manual fallback for when GitHub Actions is unavailable.
#
# The block below is commented out until that fallback is realigned with the
# new tag scheme: it predates the move of design review from alphas/ to exp/,
# and has no branch for the Alpha app at all. Left in place rather than
# deleted so the original behavior is easy to restore or port over.
#
# While this is commented out, Xcode Cloud builds use whatever
# CFBundleShortVersionString is committed in the repo and Xcode Cloud's own
# build number counter.
#
# # Update CFBundleShortVersionString to a date-based version (YYYY.MM.DD).
# DATE_VERSION=$(date -u "+%Y.%m.%d")
# echo "Setting CFBundleShortVersionString to ${DATE_VERSION}"
#
# PLISTS=(
#     "../WMF Framework/Info.plist"
#     "../Wikipedia Stickers/Info.plist"
#     "../Wikipedia/Experimental-Info.plist"
#     "../Wikipedia/Local-Info.plist"
#     "../Wikipedia/Alpha-Info.plist"
#     "../Wikipedia/Wikipedia-Info.plist"
#     "../ContinueReadingWidget/Info.plist"
#     "../WikipediaUnitTests/Info.plist"
#     "../Widgets/Info.plist"
#     "../NotificationServiceExtension/Info.plist"
# )
#
# for PLIST in "${PLISTS[@]}"; do
#     /usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${DATE_VERSION}" "${PLIST}"
#     echo "Updated ${PLIST}"
# done
#
# # Compute CFBundleVersion the same way the GitHub Actions deploy workflows
# # do: highest existing tag for this workflow's prefix, plus one. Requires
# # "Manage Version and Build Number" to be turned off for this workflow in
# # the Xcode Cloud workflow settings, otherwise Xcode Cloud will overwrite
# # the build number during the archive step. That setting only governs the
# # build number, not CFBundleShortVersionString above, which stays
# # date-based regardless.
# if [[ ${CI_WORKFLOW} == "Nightly Build" ]]; then
#     TAG_PREFIX="betas"
#     BUILD_PLIST="../Wikipedia/Wikipedia-Info.plist"
# elif [[ ${CI_WORKFLOW} == "Experimental Build" ]]; then
#     TAG_PREFIX="alphas"
#     BUILD_PLIST="../Wikipedia/Experimental-Info.plist"
# else
#     TAG_PREFIX=""
# fi
#
# if [[ -n "${TAG_PREFIX}" ]]; then
#     # Xcode Cloud's default clone can be shallow, which risks an incomplete
#     # tag list here - fetch tags explicitly rather than trust it. A failed
#     # fetch isn't fatal on its own: a stale tag list just risks a duplicate
#     # build number, which the tag push in tag_script_xcodebuild.sh will
#     # catch and fail on instead.
#     git fetch --tags origin || echo "Warning: tag fetch failed, tag list may be stale"
#
#     LATEST=$(git tag --list "${TAG_PREFIX}/*" \
#         | sed "s|${TAG_PREFIX}/||" \
#         | grep -E '^[0-9]+$' \
#         | sort -n \
#         | tail -1)
#     BUILD=$(( ${LATEST:-0} + 1 ))
#     echo "Setting CFBundleVersion to ${BUILD}"
#     /usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD}" "${BUILD_PLIST}"
# fi

echo "Version and build number management is disabled here - see TODO above."

exit 0
