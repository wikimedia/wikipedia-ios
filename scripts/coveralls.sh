#! /bin/sh

# XcodeCoverage is measuring coverage and exporting the environment, so grab it here.
source Pods/XcodeCoverage/env.sh
declare -r gcov_dir="${OBJECT_FILE_DIR_normal}/${CURRENT_ARCH}/"

# Run coveralls w/ our repo token, skipping gcov (since it's been done already)
coveralls --repo-token ${COVERALLS_REPO_TOKEN} --no-gcov \

