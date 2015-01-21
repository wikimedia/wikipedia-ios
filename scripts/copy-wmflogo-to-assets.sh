#!/bin/sh

# When Images.xcassets is compiled it creates 3 pngs from wmf_logo.pdf
# This script copies those files to the "assets/images/" folder

target_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/"
assets_path="${CONFIGURATION_BUILD_DIR}/${UNLOCALIZED_RESOURCES_FOLDER_PATH}/assets/images/"

mkdir -p $assets_path

copy_target_to_assets() {
  cp -v "${target_path}/$1" "${assets_path}/$2"
}

copy_target_to_assets "WMFLogo_60.png" "wmflogo_60.png"
copy_target_to_assets "WMFLogo_60@2x.png" "wmflogo_120.png"
copy_target_to_assets "WMFLogo_60@3x.png" "wmflogo_180.png"