#! /bin/sh
# Update Info.plist in the app bundlebased on current build configuration.
# This script should only be at the end of a build to ensure:
#   - The .app folder exists
#   - the plist has been preprocessed
# Processing is done inside the .app to prevent changes to repository status

declare -r INFO_PLIST="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Info.plist"

# Fail if any subsequent commands fail
set -e

if [[ "${CONFIGURATION}" != "Release" ]]; then
  echo "Showing debug menu for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" WMFShowDebugMenu -bool YES
fi

if [[ "${CONFIGURATION}" == "Beta" ]]; then
  echo "Setting Hockey App ID for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" WMFHockeyAppIdentifier -string $HOCKEY_BETA
  defaults write "${INFO_PLIST}" WMFPiwikURL -string $PIWIK_URL
  defaults write "${INFO_PLIST}" WMFPiwikAppIdentifier -string $PIWIK_BETA
fi

if [[ "${CONFIGURATION}" == "Release" ]]; then
  echo "Setting Hockey App ID for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" WMFHockeyAppIdentifier -string $HOCKEY_PRODUCTION
  defaults write "${INFO_PLIST}" WMFPiwikURL -string $PIWIK_URL
  defaults write "${INFO_PLIST}" WMFPiwikAppIdentifier -string $PIWIK_PRODUCTION
fi
