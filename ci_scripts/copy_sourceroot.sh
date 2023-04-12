 #!/bin/sh
 
if [[ ${CI_XCODEBUILD_ACTION} == "build-for-testing" ]]; then
    cd ../WikipediaUnitTests/
    SOURCEROOT="${CI_WORKSPACE}/ci_scripts"
    plutil -replace SourceRoot -string $SOURCEROOT Info.plist
    plutil -p Info.plist
    echo "CI_WORKSPACE value successfully copied into Info.plist SourceRoot key."
    exit 0
else
    echo "Did not execute copy source root."
    exit 0
fi
