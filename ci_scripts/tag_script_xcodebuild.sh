 #!/bin/sh

if [[ ${CI_WORKFLOW} == "Nightly Build" ]]; then
	TAG_PREFIX="betas"
elif [[ ${CI_WORKFLOW} == "Experimental Build" ]]; then
	TAG_PREFIX="alphas"
else
	echo "Unrecognized workflow for tagging: ${CI_WORKFLOW}"
	exit 1
fi

if [[ ${CI_XCODEBUILD_EXIT_CODE} == 0 && ! -z ${CI_APP_STORE_SIGNED_APP_PATH} ]]; then
	BUILD_TAG="${TAG_PREFIX}/${CI_BUILD_NUMBER}"
	git tag $BUILD_TAG
	git push --tags https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/wikimedia/wikipedia-ios.git
	echo "Successfully tagged ${BUILD_TAG}"
	exit 0
else
	echo "Failure adding tag."
	exit 1
fi