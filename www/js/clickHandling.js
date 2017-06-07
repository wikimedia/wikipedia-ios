const refs = require('./refs')
const utilities = require('./utilities')
const tableCollapser = require('wikimedia-page-library').CollapseTable

const ItemType = {
  unknown: 0,
  link: 1,
  image: 2,
  reference: 3
}

class ClickedItem {
  constructor(target, href) {
    this.target = target
    this.href = href
  }
  type() {
    if (refs.isCitation(this.href)) {
      return ItemType.reference
    } else if (this.target.tagName === 'IMG' && this.target.getAttribute( 'data-image-gallery' ) === 'true') {
      return ItemType.image
    } else if (this.href) {
      return ItemType.link
    }
    return ItemType.unknown  }
}

/**
 * Send messages to native land for respective click types.
 * @return `true` if a message was sent, otherwise `false`.
 */
function sendMessageForClickedItem(item){
  switch(item.type()) {
  case ItemType.link:
    sendMessageForLinkWithHref(item.href)
    break
  case ItemType.image:
    sendMessageForImageWithTarget(item.target)
    break
  case ItemType.reference:
    sendMessageForReferenceWithTarget(item.target)
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
  sendMessageForClickedItem(new ClickedItem(target, href))
}

document.addEventListener('click', function (event) {
  event.preventDefault()
  handleClickEvent(event)
}, false)