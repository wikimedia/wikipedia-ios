# This script takes icon-prod.svg and creates pngs used for AppIcon assets. 
#
# Note: it's much easier to just run this in Ubuntu:
#   - copy this script and icon-prod.svg to a folder
#   - with terminal change to that folder
#   - then run './make-icons-from-svg.sh' 
#   - the various png resolutions specified below will be output to the folder

ruby -e '[29,40,50,57,58,80,100,72,76,87,114,120,144,152,180].each { |x| `inkscape --export-png ./icon_#{x}.png -w #{x} icon-prod.svg` }'

ruby -e '[29,58,80,120].each { |x| `inkscape --export-png ./icon_#{x}_copy.png -w #{x} icon-prod.svg` }'

