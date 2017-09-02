var wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.utilities = require('./js/utilities')
wmf.platform = require('wikimedia-page-library').PlatformTransform

window.wmf = wmf