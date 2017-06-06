var refs = require('./refs')
var utilities = require('./utilities')
var tableCollapser = require('wikimedia-page-library').CollapseTable

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(event, hrefTarget){
  if (!hrefTarget) {
    return false
  }

  var href = hrefTarget.getAttribute( 'href' )
  if (hrefTarget.getAttribute( 'data-action' ) === 'edit_section') {
    window.webkit.messageHandlers.editClicked.postMessage({ sectionId: hrefTarget.getAttribute( 'data-id' ) })
  } else if (href && refs.isCitation(href)) {
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

function handleClickEvent(event){
/*
there are certain elements which don't have an <a> ancestor, so if we fail to find it,
specify the event's target instead
*/
  var didSendMessage = maybeSendMessageForTarget(event, utilities.findClosest(event.target, 'A') || event.target)
  var hasSelectedText = window.getSelection().rangeCount > 0
  if (!didSendMessage && !hasSelectedText) {
    window.webkit.messageHandlers.nonAnchorTouchEndedWithoutDragging.postMessage({
      id: event.target.getAttribute( 'id' ),
      tagName: event.target.tagName
    })
  }
}

document.addEventListener('click', function (event) {
  event.preventDefault()
  handleClickEvent(event)
}, false)