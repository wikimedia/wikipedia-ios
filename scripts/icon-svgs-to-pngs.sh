#!/bin/sh

ruby -e '[29,40,50,57,58,72,76,80,87,90,100,114,120,144,152,180].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/AppIcon.appiconset/icon#{x}.png" -w #{x} '"$SCRIPT_INPUT_FILE_0"'` }'

ruby -e '[87,120,180].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/AppIcon.appiconset/icon#{x}-1.png" -w #{x} '"$SCRIPT_INPUT_FILE_0"'` }'

ruby -e '[120,240,360].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/RecentPagesEmpty.imageset/recent#{x}.png" -w #{x} '"$SCRIPT_INPUT_FILE_1"'` }'

ruby -e '[120,240,360].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/SavedPagesEmpty.imageset/savedpages#{x}.png" -w #{x} '"$SCRIPT_INPUT_FILE_2"'` }'

ruby -e '[60,120,180].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/WMFLogo_60.imageset/wmflogo_#{x}.png" -w #{x} '"$SCRIPT_INPUT_FILE_3"'` }'

ruby -e '[60,120,180].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "www/images/wmflogo_#{x}.png" -w #{x} '"$SCRIPT_INPUT_FILE_3"'` }'
