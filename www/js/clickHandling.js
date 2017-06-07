const refs = require('./refs')
const utilities = require('./utilities')
const tableCollapser = require('wikimedia-page-library').CollapseTable

const ClickTypeEnum = {
  unknown: 0,
  link: 1,
  image: 2,
  reference: 3
}

function clickTypeForTarget(target, href){
  if (refs.isCitation(href)) {
    return ClickTypeEnum.reference
  } else if (target.tagName === 'IMG' && target.getAttribute( 'data-image-gallery' ) === 'true') {
    return ClickTypeEnum.image
  } else if (href) {
    return ClickTypeEnum.link
  }
  return ClickTypeEnum.unknown
}

/**
 * Send messages to native land for respective click types.
 * @return `true` if a message was sent, otherwise `false`.
 */
function sendMessageForClickType(clickType, target, href){
  switch(clickType) {
  case ClickTypeEnum.link:
    sendMessageForLinkWithHref(href)
    break
  case ClickTypeEnum.image:
    sendMessageForImageWithTarget(target)
    break
  case ClickTypeEnum.reference:
    sendMessageForReferenceWithTarget(target)
    break
  default:
    return false
  }
  return true
}

function sendMessageForLinkWithHref(href){
  if(href[0] === '#'){
    tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)))
  }
  window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
}

function sendMessageForImageWithTarget(target){
  window.webkit.messageHandlers.imageClicked.postMessage({
    'src': target.getAttribute('src'),
    'width': target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
    'height': target.naturalHeight,
    'data-file-width': target.getAttribute('data-file-width'),
    'data-file-height': target.getAttribute('data-file-height')
  })
}

function sendMessageForReferenceWithTarget(target){
  refs.sendNearbyReferences( target )
}

function handleClickEvent(event){
  const target = event.target
  if(!target) {
    return
  }
  // Find anchor for non-anchor targets - like images.
  const anchorForTarget = utilities.findClosest(target, 'A') || target
  if(!anchorForTarget) {
    return
  }
  const href = anchorForTarget.getAttribute( 'href' )
  if(!href) {
    return
  }
  const clickType = clickTypeForTarget(target, href)
  sendMessageForClickType(clickType, target, href)
}

document.addEventListener('click', function (event) {
  event.preventDefault()
  handleClickEvent(event)
}, false)