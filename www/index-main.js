var wmf = {}

wmf.compatibility = require('wikimedia-page-library').CompatibilityTransform
wmf.elementLocation = require('./js/elementLocation')
wmf.utilities = require('./js/utilities')
wmf.findInPage = require('./js/findInPage')
wmf.footerReadMore = require('./js/transforms/footerReadMore')
wmf.footerMenu = require('./js/transforms/footerMenu')
wmf.footerLegal = require('./js/transforms/footerLegal')
wmf.footerContainer = require('./js/transforms/footerContainer')
wmf.filePages = require('./js/transforms/disableFilePageEdit')
wmf.tables = require('./js/transforms/collapseTables')
wmf.themes = require('wikimedia-page-library').ThemeTransform
wmf.redLinks = require('wikimedia-page-library').RedLinks
wmf.paragraphs = require('./js/transforms/relocateFirstParagraph')
wmf.images = require('./js/transforms/widenImages')

window.wmf = wmf