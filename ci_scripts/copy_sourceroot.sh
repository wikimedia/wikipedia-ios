 #!/bin/sh
 
 set -e
 
 cd WikipediaUnitTests/
 plutil -replace SourceRoot -string $CI_WORKSPACE Info.plist
 plutil -p Info.plist
 echo "CI_WORKSPACE value successfully copied into Info.plist SourceRoot key."
 exit 0
