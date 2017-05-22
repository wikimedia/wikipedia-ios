(function () {
  var refs = require('./refs')
  var utilities = require('./utilities')
  var tableCollapser = require('wikimedia-page-library').CollapseTable

  document.onclick = function() {
    // Reminder: resist adding any click/tap handling here - they can
    // "fight" with items in the touchEndedWithoutDragging handler.
    // Add click/tap handling to touchEndedWithoutDragging instead.
    event.preventDefault() // <-- Do not remove!
  }

  // track where initial touches start
  var touchDownY = 0.0
  document.addEventListener(
            'touchstart',
            function (event) {
              touchDownY = parseInt(event.changedTouches[0].clientY)
            }, false)

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
  function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
      return false
    }
 
    /*
    "touchstart" is fired when you do a peek in WKWebView, but when the peek view controller
    is presented, it appears the JS for the then covered webview more or less pauses, and
    the matching "touchend" does't get called until the view is again shown and touched (the
    hanging "touchend" seems to fire just before that new touch's "touchstart").
    This is troublesome because that delayed call to "touchend" ends up causing the image or
    link click handling to be called when the user touches the article again, even though
    that image or link is probably not what the user is interacting with now. Thankfully we
    can check for this weird condition because when it happens the number of touches hasn't
    gone to 0 yet. So we check here and bail if that's the case.
    */
    var didDetectHangingTouchend = event.touches.length > 0
    if(didDetectHangingTouchend){
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

  function touchEndedWithoutDragging(event){
    /*
     there are certain elements which don't have an <a> ancestor, so if we fail to find it,
     specify the event's target instead
     */
    var didSendMessage = maybeSendMessageForTarget(event, utilities.findClosest(event.target, 'A') || event.target)

    var hasSelectedText = window.getSelection().rangeCount > 0

    if (!didSendMessage && !hasSelectedText) {
      // Do NOT prevent default behavior -- this is needed to for instance
      // handle deselection of text.
      window.webkit.messageHandlers.nonAnchorTouchEndedWithoutDragging.postMessage({
        id: event.target.getAttribute( 'id' ),
        tagName: event.target.tagName
      })

    }
  }

  function handleTouchEnded(event){
    var touchobj = event.changedTouches[0]
    var touchEndY = parseInt(touchobj.clientY)
    if (touchDownY - touchEndY === 0 && event.changedTouches.length === 1) {
      // None of our tap events should fire if the user dragged vertically.
      touchEndedWithoutDragging(event)
    }
  }

  document.addEventListener('touchend', handleTouchEnded, false)

})()