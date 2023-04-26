 #!/bin/sh

if [[ ${CI_XCODEBUILD_EXIT_CODE} == 0 && ! -z ${CI_APP_STORE_SIGNED_APP_PATH} ]]; then
	BUILD_TAG="betas/${CI_BUILD_NUMBER}"
	git tag $BUILD_TAG
	git push --tags https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/wikimedia/wikipedia-ios.git
	echo "Successfully tagged ${BUILD_TAG}"
	exit 0
else
	echo "Failure adding tag."
	exit 1
fi