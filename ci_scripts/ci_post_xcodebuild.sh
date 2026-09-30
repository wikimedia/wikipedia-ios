 #!/bin/sh

# Stop running the script in case a command returns
# a nonzero exit code.
set -e

if [[ ${CI_WORKFLOW} == "Nightly Build" || ${CI_WORKFLOW} == "Experimental Build" ]]; then
	./tag_script_xcodebuild.sh
	echo "Execute tag script."
	exit 0
else
	echo "Do not execute tag script."
	exit 0
fi
