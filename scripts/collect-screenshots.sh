#! /bin/sh

PRODUCT_DIR=".."
PROJECT_NAME="Wikipedia"
DERIVED_DATA_PATH="/tmp/DerivedDataCLI"
SCREENSHOTS_PATH="/tmp/screenshots"

rm -rf $DERIVED_DATA_PATH
rm -rf $SCREENSHOTS_PATH
xcodebuild -scheme WikipediaScreenshots -project "${PRODUCT_DIR}/${PROJECT_NAME}.xcodeproj" -derivedDataPath "${DERIVED_DATA_PATH}" -destination 'platform=iOS Simulator,name=iPhone 12,OS=14.4' build test
xcodebuild -scheme WikipediaScreenshots -project "${PRODUCT_DIR}/${PROJECT_NAME}.xcodeproj" -derivedDataPath "${DERIVED_DATA_PATH}" -destination 'platform=iOS Simulator,name=iPad Pro (9.7-inch),OS=13.7' build test

cd ${DERIVED_DATA_PATH}/Logs/Test/
for i in *.xcresult; do
    xcparse screenshots --os --model --test-plan-config $i ${SCREENSHOTS_PATH}
done

exit 0
