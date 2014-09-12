#!/usr/local/bin/fontforge

# Created by Monte Hurd on 9/1/14.
# Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
#
# Extracts svg for each glyph in "./font.ttf" to "./svgs/" folder.
# Also extracts font settings to "./font.json" file.

# The svgs can then be edited (or added/removed) and the 
# "makeFontFromSvgs.py" script can be run to rebuild the
# font from the svgs.

# See "makeFontFromSvgs.py" for svg file naming convention.

# Invoke with command:
#    fontforge -script makeSvgsFromFont.py
#

import fontforge
import json
import os

# Ensure the svgs folder exists.
svgFolder = "./svgs/"
try:
    os.makedirs(svgFolder)
except OSError:
    if os.path.exists(svgFolder):
        pass
    else:
        raise

# Open the font file.
font = fontforge.open("font.ttf")
print font.fontname

# Export font glyphs to svgs.
print "\nExporting svgs:"
for g in font.glyphs():
  if g.unicode != -1:
    svgPath = "%s%04X %s %d %d %d.svg" % (svgFolder, g.unicode, g.glyphname, g.left_side_bearing, g.right_side_bearing, g.boundingBox()[1])
    print "\t%s" % (svgPath)
    g.export(svgPath)

# Export font settings to json.
fontInfo = {
    "fontname": font.fontname,
    "fullname": font.fullname,
    "familyname": font.familyname,
    "weight": font.weight,
    "version": font.version,
    "encoding": font.encoding,
    "copyright": font.copyright
}

# Write json data.
file = open("./font.json", "w")
file.write(json.dumps(fontInfo, indent=4, sort_keys=True))

# Done!
font.close()
print "Finished exporting.\n"

