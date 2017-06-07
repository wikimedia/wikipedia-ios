var refs = require('./refs')
var utilities = require('./utilities')
var tableCollapser = require('wikimedia-page-library').CollapseTable

const ClickTypeEnum = {
  unknown: 0,
  link: 1,
  image: 2,
  reference: 3
}

function clickTypeForTarget(hrefTarget, event){
  if (!hrefTarget) {
    return ClickTypeEnum.unknown
  }
  var href = hrefTarget.getAttribute( 'href' )
  if (href && refs.isCitation(href)) {
    return ClickTypeEnum.reference
  } else if (event.target.tagName === 'IMG' && event.target.getAttribute( 'data-image-gallery' ) === 'true') {
    return ClickTypeEnum.image
  } else if (href) {
    return ClickTypeEnum.link
  }
  return ClickTypeEnum.unknown
}

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(hrefTarget, event){
  var href = hrefTarget.getAttribute( 'href' )
  switch(clickTypeForTarget(hrefTarget, event)) {
  case ClickTypeEnum.link:
    if(href[0] === '#'){
      tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)))
    }
    window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
    break
  case ClickTypeEnum.image:
    window.webkit.messageHandlers.imageClicked.postMessage({
      'src': event.target.getAttribute('src'),
      'width': event.target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
      'height': event.target.naturalHeight,
      'data-file-width': event.target.getAttribute('data-file-width'),
      'data-file-height': event.target.getAttribute('data-file-height')
    })
    break
  case ClickTypeEnum.reference:
    refs.sendNearbyReferences( hrefTarget )
    break
  default:
    return false
  }
  return true
}

document.addEventListener('click', function (event) {
  event.preventDefault()
  /*
  There are certain elements which don't have an <a> ancestor, so if we fail to find it,
  specify the event's target instead.
  */
  var target = utilities.findClosest(event.target, 'A') || event.target
  maybeSendMessageForTarget(target, event)
}, false)