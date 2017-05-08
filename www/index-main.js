var wmf = {};

wmf.elementLocation = require("./js/elementLocation");
wmf.utilities = require("./js/utilities");
wmf.findInPage = require("./js/findInPage");
wmf.footerReadMore = require("./js/transforms/footerReadMore");
wmf.footerMenu = require("./js/transforms/footerMenu");
wmf.footerLegal = require("./js/transforms/footerLegal");
wmf.filePages = require("./js/transforms/disableFilePageEdit");
wmf.tables = require("./js/transforms/collapseTables");
wmf.redlinks = require("./js/transforms/hideRedlinks");
wmf.paragraphs = require("./js/transforms/relocateFirstParagraph");
wmf.images = require("./js/transforms/widenImages");

window.wmf = wmf;