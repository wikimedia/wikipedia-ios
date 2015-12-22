# Wikipedia App Icons

> **TL;DR; Make sure you have both ghostscript and imagemagick installed via Homebrew to generate app icons, and that you modify the `AppIcon` in `SourceIcons.xcassets` when making changes to the app icon.**

## Overview

In order to clarify which version of the app is being used, we add overlays to the app icon depending on the configuration (see `scripts/process-icons.sh`).  In order for this to work w/ Xcode asset catalogs, we have two catalogs:

- Images.xcassets
- SourceIcons.xcassets

The first is the main asset catalog, where all bundled images are stored for buttons etc.  The second, **SourceIcons.xcassets**, is used to store the "source" app icon, which is used as the template when generating overlaid app icon.  This means that the app icons will appear "empty" on a clean checkout.

## Generating App Icons

1. Install imagemagick and ghostscript via Homeview: `brew install imagemagick ghostscript`
2. Build the project

This should have run `scripts/process-icons.sh`, and generated app icons for the current configuration (most likely Debug).

## Modifying App Icons
Modify `SourceIcons.xcassets/AppIcon`, then delete derived data and rebuild the project to ensure your changes are propagated to `Images.xcassets` successfully.

