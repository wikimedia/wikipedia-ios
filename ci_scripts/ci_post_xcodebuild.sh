 #!/bin/sh

BUILD_TAG="betas/${CI_BUILD_NUMBER}"
git tag $BUILD_TAG
git push --tags https://${GITHUB_PAT}@github.com/wmf_apps_ci/https://github.com/wikimedia/wikipedia-ios.git