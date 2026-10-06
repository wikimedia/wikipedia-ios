 #!/bin/sh

# Stop running the script in case a command returns
# a nonzero exit code.
set -e

# TODO: Tagging happens in the GitHub Actions deploy workflows now
# (v2_deploy_design_review pushes exp/, v2_deploy_alpha pushes alphas/,
# v2_deploy_beta pushes betas/), which are the primary deploy path. Xcode
# Cloud stays available as a manual fallback for when GitHub Actions is
# unavailable - re-enable this once that fallback's tag prefixes have been
# realigned with the scheme above.
#
# if [[ ${CI_WORKFLOW} == "Nightly Build" || ${CI_WORKFLOW} == "Experimental Build" ]]; then
# 	./tag_script_xcodebuild.sh
# 	echo "Execute tag script."
# 	exit 0
# else
# 	echo "Do not execute tag script."
# 	exit 0
# fi

echo "Tagging from Xcode Cloud is disabled - see TODO above."
exit 0
