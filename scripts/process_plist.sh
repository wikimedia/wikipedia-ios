#! /bin/sh
# Update Info.plist in the app bundlebased on current build configuration.
# This script should only be at the end of a build to ensure:
#   - The .app folder exists
#   - the plist has been preprocessed
# Processing is done inside the .app to prevent changes to repository status

declare -r INFO_PLIST="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/Info.plist"

# Fail if any subsequent commands fail
set -e

if [[ "${CONFIGURATION}" != "Release" || $WMF_FORCE_ITUNES_FILE_SHARING == "1" ]]; then
  echo "Enabling iTunes File Sharing for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" UIFileSharingEnabled -bool YES
fi

if [[ "${CONFIGURATION}" != "Release" || $WMF_FORCE_DEBUG_MENU == "1" ]]; then
  echo "Showing debug menu for ${CONFIGURATION} build."
  defaults write "${INFO_PLIST}" WMFShowDebugMenu -bool YES
fi

echo "Setting Hockey App ID for ${CONFIGURATION} build."
defaults write "${INFO_PLIST}" WMFHockeyAppIdentifier -string $WMF_HOCKEYAPP_IDENTIFIER
echo "Setting Piwik URL for ${CONFIGURATION} build."
defaults write "${INFO_PLIST}" WMFPiwikURL -string $WMF_PIWIK_URL
echo "Setting Piwik App ID for ${CONFIGURATION} build."
defaults write "${INFO_PLIST}" WMFPiwikAppIdentifier -string $WMF_PIWIK_APP_IDENTIFIER
