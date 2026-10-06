 #!/bin/sh

set -e

# TODO: This whole script is disabled. Tagging happens in the GitHub Actions
# deploy workflows now (v2_deploy_design_review pushes exp/, v2_deploy_alpha
# pushes alphas/, v2_deploy_beta pushes betas/), which are the primary deploy
# path. Xcode Cloud stays available as a manual fallback for when GitHub
# Actions is unavailable - re-enable or port this over once that fallback's
# prefixes have been realigned. Note the mapping below is the OLD one, where
# "Experimental Build" claimed alphas/ rather than exp/.
#
# Its caller, ci_post_xcodebuild.sh, is commented out too, so nothing
# invokes this today.
#
# if [[ ${CI_WORKFLOW} == "Nightly Build" ]]; then
# 	TAG_PREFIX="betas"
# 	BUILD_PLIST="../Wikipedia/Wikipedia-Info.plist"
# elif [[ ${CI_WORKFLOW} == "Experimental Build" ]]; then
# 	TAG_PREFIX="alphas"
# 	BUILD_PLIST="../Wikipedia/Experimental-Info.plist"
# else
# 	echo "Unrecognized workflow for tagging: ${CI_WORKFLOW}"
# 	exit 1
# fi
#
# if [[ ${CI_XCODEBUILD_EXIT_CODE} == 0 && ! -z ${CI_APP_STORE_SIGNED_APP_PATH} ]]; then
# 	# Read the build number back from the plist rather than trusting
# 	# CI_BUILD_NUMBER, which is Xcode Cloud's own internal counter and
# 	# never reflects what ci_pre_xcodebuild.sh actually computed/set here.
# 	BUILD_NUMBER=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${BUILD_PLIST}")
# 	BUILD_TAG="${TAG_PREFIX}/${BUILD_NUMBER}"
# 	git tag $BUILD_TAG
# 	git push --tags https://${GITHUB_USERNAME}:${GITHUB_PAT}@github.com/wikimedia/wikipedia-ios.git
# 	echo "Successfully tagged ${BUILD_TAG}"
# 	exit 0
# else
# 	echo "Failure adding tag."
# 	exit 1
# fi

echo "tag_script_xcodebuild.sh is disabled - see TODO above."
exit 0
