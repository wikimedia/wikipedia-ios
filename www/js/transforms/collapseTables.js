const tableCollapser = require('wikimedia-page-library').CollapseTable
let location = require('../elementLocation')

const footerDivClickCallback = container => {
  if(location.isElementTopOnscreen(container)){
    window.scrollTo( 0, container.offsetTop - 10 )
  }
}

const hideTables = (content, isMainPage, pageTitle, infoboxTitle, otherTitle, footerTitle) => {
  tableCollapser.collapseTables(window, content, pageTitle, isMainPage, infoboxTitle, otherTitle, footerTitle, footerDivClickCallback)
}

exports.hideTables = hideTables