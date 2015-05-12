#! /usr/bin/env ruby

# This script uses convert (from imagemagick) to convert icon-prod.svg into pngs used for AppIcon assets.
# To run:
#	- cd to the project's "wikipedia" dir via terminal
#	- run "./scripts/make-icons-from-svg.sh"

require 'fileutils'

def convert(x, path)
  puts "Converting svgs/icon-prod.svg to #{x}x#{x} png..."
  `convert -density 500 -resize #{x}x#{x} svgs/icon-prod.svg "#{path}icon_#{x}.png"`
end

def makedupe(x, path)
  puts "Making dupe of #{x}..."
  FileUtils.copy_file("#{path}icon_#{x}.png", "#{path}icon_#{x}_copy.png")
end

outputPath = "./Wikipedia/SourceIcons.xcassets/AppIconSource.appiconset/"

[29,40,50,57,58,80,100,72,76,87,114,120,144,152,180].each { |x| convert x, outputPath }

[29,58,80,120].each { |x| makedupe x, outputPath }
