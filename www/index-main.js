var wmf = {}

wmf.elementLocation = require('./js/elementLocation')
wmf.utilities = require('./js/utilities')
wmf.findInPage = require('./js/findInPage')
wmf.footerReadMore = require('wikimedia-page-library').FooterReadMore
wmf.footerMenu = require('wikimedia-page-library').FooterMenu
wmf.footerLegal = require('wikimedia-page-library').FooterLegal
wmf.footerContainer = require('wikimedia-page-library').FooterContainer
wmf.filePages = require('./js/transforms/disableFilePageEdit')
wmf.tables = require('./js/transforms/collapseTables')
wmf.redLinks = require('wikimedia-page-library').RedLinks
wmf.paragraphs = require('./js/transforms/relocateFirstParagraph')
wmf.images = require('./js/transforms/widenImages')

window.wmf = wmf