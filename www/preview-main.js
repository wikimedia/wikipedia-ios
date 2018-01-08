const wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.utilities = require('./js/utilities')
wmf.platform = require('wikimedia-page-library').PlatformTransform
wmf.imageDimming = require('wikimedia-page-library').DimImagesTransform

window.wmf = wmf