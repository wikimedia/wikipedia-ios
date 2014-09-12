#!/usr/local/bin/fontforge

# Created by Monte Hurd on 9/1/14.
# Copyright (c) 2014 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!
#
# Makes "./font.ttf" from svg files found in "./svgs/".
# Svg's must be named according to following convention:
#     "UNICODE_CHAR GLYPH_NAME LEFT_BEARING RIGHT_BEARING BASELINE_OFFSET.svg"
#
# Example: "e950 MY_GLYPH 80 100 150.svg"
#	   This will be mapped to the font character e950 with glyph
#          name "MyGlyph" and left bearing (padding) of 80, right
#          bearing of 100 and will sit 150 above the baseline.
#
# Note: running the "makeSvgsFromFont.py" script will generate
#     such an svg (named according to the convention) for each 
#     glyph found in font.ttf. It will also generate a font.json file.
#
# Run this script with command: 
#     fontforge -script makeFontFromSvgs.py
#
# References:
#    http://fontforge.org/python.html
#    http://tex.stackexchange.com/questions/22487/create-a-symbol-font-from-svg-symbols
#    http://fontforge.org/scripting.html
#    http://stderr.org/doc/fontforge/html/scripting-alpha.html#GlyphInfo

import fontforge
import glob
import json

# Create font object.
font = fontforge.font()

# Apply font settings from font.json
config = json.loads(open('./font.json').read())
font.fontname = config["fontname"]
font.fullname = config["fullname"]
font.familyname = config["familyname"]
font.weight = config["weight"]
font.version    = config["version"]
font.encoding   = config["encoding"]
font.copyright  = config["copyright"]

# This is the name used when generating the font file.
fileName = "font"

# Folders!
svgFolder = "./svgs/"
outputFolder = "./"

# Build array of glyph info dictionaries.
print "\nStarted importing glyphs into " + fileName
glyphDictionaries = []
for fullName in glob.glob(svgFolder + '*.svg'):
    fullName = fullName[len(svgFolder):]
    words = fullName.split()
    if (len(words) == 5):
        glyphDictionary = {}
        glyphDictionary["fullName"] = fullName
        glyphDictionary["unicodeChar"] = words[0]
        glyphDictionary["name"] = words[1]
        glyphDictionary["bearingLeft"] = words[2]
        glyphDictionary["bearingRight"] = words[3]
        glyphDictionary["baselineOffset"] = words[4][:-4]
        glyphDictionaries.append(glyphDictionary)

# Sort it!
glyphDictionaries.sort(key=lambda x: x['name'])

# Add glyph for each dictionary entry to font object.
for glyphDictionary in glyphDictionaries:
        # Put new glyphs in the Private Use Area.
        glyph = font.createChar(int("0x{}".format(glyphDictionary["unicodeChar"]),0), glyphDictionary["name"])
        
        print "\tImporting \"" + glyphDictionary["fullName"] + "\""
        # Import svg data into the glyph.
        glyph.importOutlines(svgFolder + glyphDictionary["fullName"])
	
        # Make the glyph rest on the baseline + offset from file name.
        ymin = glyph.boundingBox()[1]
        glyph.transform([1, 0, 0, 1, 0, -ymin + int(glyphDictionary["baselineOffset"])])
        
        # Set glyph side bearings with values from file name.
        glyph.left_side_bearing = int(glyphDictionary["bearingLeft"])
        glyph.right_side_bearing = int(glyphDictionary["bearingRight"])

# Run various fontforge methods.
#font.canonicalContours()
font.round() # Needed to make simplify more reliable.
font.simplify()
font.removeOverlap()
font.round()
font.autoHint()

# Generate actual font files.
#font.generate(outputFolder + fileName + ".pfb", flags=["tfm", "afm"]) # type1 with tfm/afm
#font.generate(outputFolder + fileName + ".otf") # opentype
font.generate(outputFolder + fileName + ".ttf") # truetype
print "Finished generating " + outputFolder + fileName + ".ttf"

# Build css file.
cssFileContentsHeader = """
@font-face {
    font-family: '%s';
    /* src: url('%s.eot'); */ /* IE9 Compat Modes */
    src: url('%s.ttf') format('truetype'); /* Safari, Android, iOS */ 

         /* url('%s.eot?#iefix') format('embedded-opentype'), */ /* IE6-IE8 */
         /* url('%s.woff') format('woff'), */ /* Modern Browsers */
         /* url('%s.svg#8088f7bbbdba5c9832b27edb3dfcdf09') format('svg'); */ /* Legacy iOS */
}
.glyph {
    display: inline-block;
    height: 2.0em;
    width: 2.0em;
    text-align:center;
    font-family: '%s';
    -webkit-font-smoothing: antialiased;
    font-size: inherit;
    font-style: normal;
    font-weight: normal;
    line-height: 2.0em;
    overflow: visible;
}
.glyph[dir='rtl'] {
  filter: progid:DXImageTransform.Microsoft.BasicImage(rotation=0, mirror=1);
  -webkit-transform: scale(-1, 1);
  -moz-transform: scale(-1, 1);
  -ms-transform: scale(-1, 1);
  -o-transform: scale(-1, 1);
  transform: scale(-1, 1);
}
"""

cssFileContentsHeader = cssFileContentsHeader % (font.familyname, fileName, fileName, fileName, fileName, fileName, font.familyname)

file = open(outputFolder + "font.css", "w")
file.write(cssFileContentsHeader)
for glyphDictionary in glyphDictionaries:
        cssClassForGlyph = """
            .%s:before {
                content:"\%s";
            }
        """
	cssClassForGlyph = cssClassForGlyph % (glyphDictionary["name"], glyphDictionary["unicodeChar"])
        file.write(cssClassForGlyph)

file.close()

# Build html file.
htmlFileContentsHeader = """
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>%s minimal code</title>
    <link rel="stylesheet" href="font.css">
    <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate" />
    <meta http-equiv="Pragma" content="no-cache" />
    <meta http-equiv="Expires" content="0" />
</head>
<style>
    body {
        margin: 2%% 15%% 2%% 15%%;
        color: #555;
        font-family: sans-serif;
        font-size: 2.0em;
    }

    hr { color: grey; }

    div {
        display: block;
        color: #777;
        border-bottom: 1px solid #eee;
        margin: 0.5em 0 0.5em 0;
    }
    div:hover {
        border-bottom-color: #cef;
    }
    span {
        color: #111;
    }
</style>
<body>
"""

htmlFileContentsHeader = htmlFileContentsHeader % (fileName)

file = open(outputFolder + "font.html", "w")
file.write(htmlFileContentsHeader)

file.write("<h1>Glyphs</h1>")

# Grid of glyphs for top of html file.
counter = 0
for glyphDictionary in glyphDictionaries:
        divForGlyph = """
            <span class="glyph %s"></span>
        """
	divForGlyph = divForGlyph % (glyphDictionary["name"])
        file.write(divForGlyph)
	counter += 1
	if (counter % 8) == 0:
            file.write("<br>")



settingsHTML = """
<h6>
Reminder: when you've generated a new font, you may need to close your browser and re-open this file before you will see your changes!
</h6>

<h1>Settings</h1>
<div>Font name = %s</div>
<div>Full name = %s</div>
<div>Family name = %s</div>
<div>Weight = %s</div>
<div>Version = %s</div>
<div>Encoding = %s</div>
<div>Copyright = %s</div>
""" % (font.fontname, font.fullname, font.familyname, font.weight, font.version, font.encoding, font.copyright)

file.write(settingsHTML)



file.write("<h1>Glyph Names</h1>")

# List of glyphs with names beneath grid.
for glyphDictionary in glyphDictionaries:
        divForGlyph = """
            <div><span class="glyph %s"></span> %s</div>
        """
	divForGlyph = divForGlyph % (glyphDictionary["name"], glyphDictionary["name"])
        file.write(divForGlyph)

file.write("\n</body>\n</html>")

file.close()
font.close()

print "Finished generating font.html and font.css files\n"


