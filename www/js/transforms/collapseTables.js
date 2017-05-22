const tableCollapser = require('wikimedia-page-library').CollapseTable
var location = require('../elementLocation')

function footerDivClickCallback(container) {
  if(location.isElementTopOnscreen(container)){
    window.scrollTo( 0, container.offsetTop - 10 )
  }
}

function hideTables(content, isMainPage, pageTitle, infoboxTitle, otherTitle, footerTitle) {
  tableCollapser.collapseTables(document, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback)
}

exports.hideTables = hideTables