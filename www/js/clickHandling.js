const refs = require('./refs')
const utilities = require('./utilities')
const tableCollapser = require('wikimedia-page-library').CollapseTable

const ClickTypeEnum = {
  unknown: 0,
  link: 1,
  image: 2,
  reference: 3
}

function clickTypeForTarget(target, hrefForTarget){
  if (refs.isCitation(hrefForTarget)) {
    return ClickTypeEnum.reference
  } else if (target.tagName === 'IMG' && target.getAttribute( 'data-image-gallery' ) === 'true') {
    return ClickTypeEnum.image
  } else if (hrefForTarget) {
    return ClickTypeEnum.link
  }
  return ClickTypeEnum.unknown
}

/**
 * Sends messages to native land for respective click types.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(target, hrefForTarget){
  switch(clickTypeForTarget(target, hrefForTarget)) {
  case ClickTypeEnum.link:
    if(hrefForTarget[0] === '#'){
      tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(hrefForTarget.substring(1)))
    }
    window.webkit.messageHandlers.linkClicked.postMessage({ 'href': hrefForTarget })
    break
  case ClickTypeEnum.image:
    window.webkit.messageHandlers.imageClicked.postMessage({
      'src': target.getAttribute('src'),
      'width': target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
      'height': target.naturalHeight,
      'data-file-width': target.getAttribute('data-file-width'),
      'data-file-height': target.getAttribute('data-file-height')
    })
    break
  case ClickTypeEnum.reference:
    refs.sendNearbyReferences( target )
    break
  default:
    return false
  }
  return true
}

document.addEventListener('click', function (event) {
  event.preventDefault()
  const anchorForTarget = utilities.findClosest(event.target, 'A') || event.target
  if(!anchorForTarget) {
    return
  }
  const hrefForTarget = anchorForTarget.getAttribute( 'href' )
  if(!hrefForTarget) {
    return
  }
  const target = event.target
  if(!target) {
    return
  }  
  maybeSendMessageForTarget(target, hrefForTarget)
}, false)