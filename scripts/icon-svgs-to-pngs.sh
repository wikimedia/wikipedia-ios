#!/bin/sh

ruby -e '[29,40,50,57,58,72,76,80,87,100,114,120,144,152,180].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/AppIcon.appiconset/icon#{x}.png" -w #{x} '"$SCRIPT_INPUT_FILE_0"'` }'

ruby -e '[120].each { |x| `/Applications/Inkscape.app/Contents/Resources/bin/inkscape --export-png "wikipedia/Images.xcassets/AppIcon.appiconset/icon#{x}-1.png" -w #{x} '"$SCRIPT_INPUT_FILE_0"'` }'
