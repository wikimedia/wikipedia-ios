var refs = require('./refs')
var utilities = require('./utilities')
var tableCollapser = require('wikimedia-page-library').CollapseTable

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(hrefTarget, event){
  if (!hrefTarget) {
    return false
  }

  var href = hrefTarget.getAttribute( 'href' )
  if (href && refs.isCitation(href)) {
      // Handle reference links with a popup view instead of scrolling about!
    refs.sendNearbyReferences( hrefTarget )
  } else if (href && href[0] === '#') {

    tableCollapser.expandCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)))

      // If it is a link to an anchor in the current page, use existing link handling
      // so top floating native header height can be taken into account by the regular
      // fragment handling logic.
    window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
  } else if (event.target.tagName === 'IMG' && event.target.getAttribute( 'data-image-gallery' ) === 'true') {
    window.webkit.messageHandlers.imageClicked.postMessage({
      'src': event.target.getAttribute('src'),
      'width': event.target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
      'height': event.target.naturalHeight,
      'data-file-width': event.target.getAttribute('data-file-width'),
      'data-file-height': event.target.getAttribute('data-file-height')
    })
  } else if (href) {
    window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href })
  } else {
    return false
  }
  return true
}

document.addEventListener('click', function (event) {
  event.preventDefault()
  /*
  there are certain elements which don't have an <a> ancestor, so if we fail to find it,
  specify the event's target instead
  */
  var target = utilities.findClosest(event.target, 'A') || event.target
  maybeSendMessageForTarget(target, event)
}, false)