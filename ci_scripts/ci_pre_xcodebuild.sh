#!/bin/sh

# Stop running the script in case a command returns
# a nonzero exit code.
set -e

../scripts/setup_bundle_id ci # in case xcode cannot find a valid team id, this will set the default one

if [[ ${CI_WORKFLOW} == "Run Tests" ]]; then
    ./copy_sourceroot.sh
    echo "Execute copy source root."
    exit 0
fi

exit 0
