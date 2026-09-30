 #!/bin/sh

set -e

if [[ ${CI_WORKFLOW} == "Nightly Build" ]]; then
	TAG_PREFIX="betas"
	BUILD_PLIST="../Wikipedia/Wikipedia-Info.plist"
elif [[ ${CI_WORKFLOW} == "Experimental Build" ]]; then
	TAG_PREFIX="alphas"
	BUILD_PLIST="../Wikipedia/Experimental-Info.plist"
else
	echo "Unrecognized workflow for tagging: ${CI_WORKFLOW}"
	exit 1
fi

if [[ ${CI_XCODEBUILD_EXIT_CODE} == 0 && ! -z ${CI_APP_STORE_SIGNED_APP_PATH} ]]; then
	# Read the build number back from the plist rather than trusting
	# CI_BUILD_NUMBER, which is Xcode Cloud's own internal counter and
	# never reflects what ci_pre_xcodebuild.sh actually computed/set here.
	BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${BUILD_PLIST}")
	BUILD_TAG="${TAG_PREFIX}/${BUILD_NUMBER}"
	git tag $BUILD_TAG
	git push --tags https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/wikimedia/wikipedia-ios.git
	echo "Successfully tagged ${BUILD_TAG}"
	exit 0
else
	echo "Failure adding tag."
	exit 1
fi