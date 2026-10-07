 #!/bin/sh

# Tags an Xcode Cloud build. GitHub Actions is the primary deploy path, so
# this runs only when a build is driven from Xcode Cloud as a fallback; the
# prefixes here mirror the ones the v2_ GitHub Actions workflows push.

set -e

if [[ ${CI_WORKFLOW} == "Beta Build" ]]; then
	TAG_PREFIX="betas"
elif [[ ${CI_WORKFLOW} == "Alpha Build" ]]; then
	TAG_PREFIX="alphas"
elif [[ ${CI_WORKFLOW} == "Experimental Build" ]]; then
	TAG_PREFIX="exp"
else
	echo "Unrecognized workflow for tagging: ${CI_WORKFLOW}"
	exit 1
fi

if [[ ${CI_XCODEBUILD_EXIT_CODE} == 0 && ! -z ${CI_APP_STORE_SIGNED_APP_PATH} ]]; then
	# Tag the build number Xcode Cloud assigned. It owns the number (see
	# ci_pre_xcodebuild.sh, which writes this same value into the plist), so
	# this is what the archive ships with.
	if [[ -z "${CI_BUILD_NUMBER}" ]]; then
		echo "CI_BUILD_NUMBER is empty - refusing to tag."
		exit 1
	fi
	BUILD_TAG="${TAG_PREFIX}/${CI_BUILD_NUMBER}"
	git tag $BUILD_TAG
	# Push this ref alone. --tags offers every local tag, which means ~2,500
	# refs negotiated to create one, and a far less readable error when it
	# fails.
	git push https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/wikimedia/wikipedia-ios.git "${BUILD_TAG}"
	echo "Successfully tagged ${BUILD_TAG}"
	exit 0
else
	echo "Failure adding tag."
	exit 1
fi
