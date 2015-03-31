(function () {
var bridge = require("./bridge");
var transformer = require("./transformer");
var refs = require("./refs");

// DOMContentLoaded fires before window.onload! That's good!
// See: http://stackoverflow.com/a/3698214/135557
document.addEventListener("DOMContentLoaded", function() {

    transformer.transform( "moveFirstGoodParagraphUp", document );
    transformer.transform( "hideRedlinks", document );
    transformer.transform( "disableFilePageEdit", document );
    transformer.transform( "addImageOverflowXContainers", document );

    bridge.sendMessage( "DOMContentLoaded", {} );
});

bridge.registerListener( "setLanguage", function( payload ){
    var html = document.querySelector( "html" );
    html.lang = payload.lang;
    html.dir = payload.dir;
    html.classList.add( 'content-' + payload.dir );
    html.classList.add( 'ui-' + payload.uidir );
    document.querySelector('base').href = 'https://' + payload.lang + '.wikipedia.org/';
} );

bridge.registerListener( "setScale", function( payload ) {
    var contentSettings = [
        "width=device-width",
        "initial-scale=1.0",
        "user-scalable=yes",
        "minimum-scale=" + payload.min,
        "maximum-scale=" + payload.max
    ];
    var content = contentSettings.join(", ");
    document.getElementById("viewport").setAttribute('content', content);
} );

bridge.registerListener( "scrollToFragment", function( payload ) {
    var item = document.getElementById( payload.hash );
    var rect = item.getBoundingClientRect();
    window.scroll( 0, rect.top );
});

bridge.registerListener( "setPageProtected", function() {
    document.getElementsByTagName( "html" )[0].classList.add( "page-protected" );
} );


bridge.registerListener( "setTableLocalization", function( payload ) {
    window.string_table_infobox = payload.string_table_infobox;
    window.string_table_other = payload.string_table_other;
    window.string_table_close = payload.string_table_close;
} );


bridge.registerListener( "collapseTables", function() {
    transformer.transform( "hideTables", document );
} );


/**
 * Quickie function to walk from the current element up to parents and match CSS-ish selectors.
 * Think of it as a reverse element.querySelector :)
 *
 * Takes only element names, raw classes, and ids right now. Combines all given.
 */
function findParent(element, selector) {
    // parse selector attributes
    var matches = selector.match(/^([a-z0-9]*)(?:\.([a-z0-9-]+))?(?:#([a-z0-9-]+))?$/i);
    if (!matches) {
        throw new Error("Unexpected findParent selector format: " + selector);
    }
    var maybeLowerCase = function (s) {
        return typeof s === 'string' ? s.toLowerCase() : undefined;
    };
    return _findParent(element,
                       maybeLowerCase(matches[1]),
                       maybeLowerCase(matches[2]),
                       maybeLowerCase(matches[3]),
                       0,
                       10);
}

/**
 * Recursively traverse an element's parents until a match is found, up to `maxDepth`.
 * @param element {HTMLElement} The element to check against provided selectors.
 * @param selectorName {String} *Lowercase* tag name to search for.
 * @param selectorClass {String} *Lowercase* class to search for.
 * @param selectorId {String} *Lowercase* id to search for.
 * @param depth {Int} The current recursion/traversal depth
 * @param maxDepth {Int} The maximum depth to traverse to.
 * @see findParent(element, selector)
 */
function _findParent(element, selectorName, selectorClass, selectorId, depth, maxDepth) {
    if (!element || depth >= maxDepth) {
        // base case, nothing found or max depth reached
        return undefined;
    } else if (selectorName && element.tagName && selectorName === element.tagName.toLowerCase()) {
        // element.tagName can be nil if we hit `document`
        return element;
    } else if (selectorClass && element.classList && element.classList.contains(selectorClass)) {
        return element;
    } else if (selectorId && element.id && selectorId === element.id) {
        return element;
    } else {
        // continue traversing
        return _findParent(element.parentNode, selectorName, selectorClass, selectorId, depth+1, maxDepth);
    }
}

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
    var didSendMessage = maybeSendMessageForTarget(event, findParent(event.target, 'A') || event.target);

    var hasSelectedText = window.getSelection().rangeCount > 0;

    if (!didSendMessage && !hasSelectedText) {
        // Do NOT prevent default behavior -- this is needed to for instance
        // handle deselection of text.
        bridge.sendMessage('nonAnchorTouchEndedWithoutDragging', {
                              id: event.target.getAttribute( "id" ),
                              tagName: event.target.tagName
                          });

    }
}

/**
 * Attempts to send a bridge message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
        return false;
    }
    var href = hrefTarget.getAttribute( "href" );
    var hrefClass = hrefTarget.getAttribute('class');
    if (hrefTarget.getAttribute( "data-action" ) === "edit_section") {
        bridge.sendMessage( 'editClicked', { sectionId: hrefTarget.getAttribute( "data-id" ) });
    } else if (href && refs.isReference(href)) {
        // Handle reference links with a popup view instead of scrolling about!
        refs.sendNearbyReferences( hrefTarget );
    } else if (href && href[0] === "#") {
        // If it is a link to an anchor in the current page, just scroll to it
        document.getElementById( href.substring( 1 ) ).scrollIntoView();
    } else if (typeof hrefClass === 'string' && hrefClass.indexOf('image') !== -1) {
        bridge.sendMessage('imageClicked', { 'url': event.target.getAttribute('src') });
    } else if (href) {
        bridge.sendMessage( 'linkClicked', { 'href': href });
    } else {
        return false;
    }
    return true;
}

document.addEventListener("touchend", handleTouchEnded, false);

bridge.registerListener( "setLeadImageDivHeight", function( payload ) {
    var div = document.getElementById( "lead_image_div" );
    if (payload.height == div.offsetHeight) return;
    div.style.height = payload.height + 'px';
});

})();
