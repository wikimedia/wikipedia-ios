(function () {
var refs = require("./refs");
var utilities = require("./utilities");

document.onclick = function() {
    // Reminder: resist adding any click/tap handling here - they can
    // "fight" with items in the touchEndedWithoutDragging handler.
    // Add click/tap handling to touchEndedWithoutDragging instead.
    event.preventDefault(); // <-- Do not remove!
};

// track where initial touches start
var touchDownY = 0.0;
document.addEventListener(
            "touchstart",
            function (event) {
                touchDownY = parseInt(event.changedTouches[0].clientY);
            }, false);

function handleTouchEnded(event){
    var touchobj = event.changedTouches[0];
    var touchEndY = parseInt(touchobj.clientY);
    if (((touchDownY - touchEndY) === 0) && (event.changedTouches.length === 1)) {
        // None of our tap events should fire if the user dragged vertically.
        touchEndedWithoutDragging(event);
    }
}

function touchEndedWithoutDragging(event){
    /*
     there are certain elements which don't have an <a> ancestor, so if we fail to find it,
     specify the event's target instead
     */
    var didSendMessage = maybeSendMessageForTarget(event, utilities.findClosest(event.target, 'A') || event.target);

    var hasSelectedText = window.getSelection().rangeCount > 0;

    if (!didSendMessage && !hasSelectedText) {
        // Do NOT prevent default behavior -- this is needed to for instance
        // handle deselection of text.
        window.webkit.messageHandlers.clicks.postMessage({"nonAnchorTouchEndedWithoutDragging": {
                                                  id: event.target.getAttribute( "id" ),
                                                  tagName: event.target.tagName
                                                  }});

    }
}

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
        return false;
    }
    var href = hrefTarget.getAttribute( "href" );
    var hrefClass = hrefTarget.getAttribute('class');
    if (hrefTarget.getAttribute( "data-action" ) === "edit_section") {
        window.webkit.messageHandlers.clicks.postMessage({"editClicked": { sectionId: hrefTarget.getAttribute( "data-id" ) }});
    } else if (href && refs.isReference(href)) {
        // Handle reference links with a popup view instead of scrolling about!
        refs.sendNearbyReferences( hrefTarget );
    } else if (href && href[0] === "#") {
        // If it is a link to an anchor in the current page, use existing link handling
        // so top floating native header height can be taken into account by the regular
        // fragment handling logic.
        window.webkit.messageHandlers.clicks.postMessage({"linkClicked": { 'href': href }});
    } else if (typeof hrefClass === 'string' && hrefClass.indexOf('image') !== -1) {
         var url = event.target.getAttribute('src');
         window.webkit.messageHandlers.clicks.postMessage({"imageClicked": {
                                                          'url': url,
                                                          'width': (event.target.naturalWidth / window.devicePixelRatio),
                                                          'height': (event.target.naturalHeight / window.devicePixelRatio)
                                                          }});

    } else if (href) {
        window.webkit.messageHandlers.clicks.postMessage({"linkClicked": { 'href': href }});
    } else {
        return false;
    }
    return true;
}

document.addEventListener("touchend", handleTouchEnded, false);

 // 3D Touch peeking listeners.
 document.addEventListener("touchstart", function (event) {
                           // Send message with url (if any) from touch element to native land.
                           window.webkit.messageHandlers.peek.postMessage({"touchedElementURL": window.wmf.elementLocation.getURLForElementAtPoint(event.changedTouches[0].pageX, event.changedTouches[0].pageY)});
                           }, false);
 
 document.addEventListener("touchend", function () {
                           // Tell native land to clear the url - important.
                           window.webkit.messageHandlers.peek.postMessage({"touchedElementURL": null});
                           }, false);
})();
