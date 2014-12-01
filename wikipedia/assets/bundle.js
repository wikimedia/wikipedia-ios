(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){

function Bridge() {
}

var eventHandlers = {};

Bridge.prototype.handleMessage = function( type, payload ) {
    var that = this;
    if ( eventHandlers.hasOwnProperty( type ) ) {
        eventHandlers[type].forEach( function( callback ) {
                                    callback.call( that, payload );
                                    } );
    }
};

Bridge.prototype.registerListener = function( messageType, callback ) {
    if ( eventHandlers.hasOwnProperty( messageType ) ) {
        eventHandlers[messageType].push( callback );
    } else {
        eventHandlers[messageType] = [ callback ];
    }
};

Bridge.prototype.sendMessage = function( messageType, payload ) {
    var messagePack = { type: messageType, payload: payload };
    var url = "x-wikipedia-bridge:" + encodeURIComponent( JSON.stringify( messagePack ) );
    
    // quick iframe version based on http://stackoverflow.com/a/6508343/82439
    // fixme can this be an XHR instead? check Cordova current state
    var iframe = document.createElement('iframe');
    iframe.setAttribute("src", url);
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};

module.exports = new Bridge();

},{}],2:[function(require,module,exports){
//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

function getZoomLevel() {
    // From: http://stackoverflow.com/a/5078596/135557
    var deviceWidth = (Math.abs(window.orientation) == 90) ? screen.height : screen.width;
    var zoom = deviceWidth / window.innerWidth;
    return zoom;
}

exports.getImageWithSrc = function(src) {
    var images = document.getElementsByTagName('IMG');
    for (var i = 0; i < images.length; ++i) {
        if (stringEndsWith(images[i].src, src)){
            return images[i];
        }
    }
    return null;
}

exports.getElementRect = function(element) {
    var rect = element.getBoundingClientRect();
    var zoom = getZoomLevel();
    var zoomedRect = new Object();
    zoomedRect['top'] = rect.top * zoom;
    zoomedRect['left'] = rect.left * zoom;
    zoomedRect['width'] = rect.width * zoom;
    zoomedRect['height'] = rect.height * zoom;
    return zoomedRect;
}

exports.getElementRectAsJson = function(element) {
    return JSON.stringify(this.getElementRect(element));
}

exports.getIndexOfFirstOnScreenElementWithTopGreaterThanY = function(elementPrefix, elementCount, y){
    for (var i = 0; i < elementCount; ++i) {
        var div = document.getElementById(elementPrefix + i);
        if(div == null) continue;
	var rect = this.getElementRect(div);
        if( (rect['top'] >= 0) || ((rect['top'] + rect['height']) >= 0)) return i;
    }
    return -1;
}

},{}],3:[function(require,module,exports){
var bridge = require("./bridge");
var transformer = require("./transformer");
var refs = require("./refs");

// DOMContentLoaded fires before window.onload! That's good!
// See: http://stackoverflow.com/a/3698214/135557
document.addEventListener("DOMContentLoaded", function(event) {

    transformer.transform( "relocateInfobox", document );
    transformer.transform( "hideRedlinks", document );
    transformer.transform( "disableFilePageEdit", document );

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

/**
 * Quickie function to walk from the current element up to parents and match CSS-ish selectors.
 * Think of it as a reverse element.querySelector :)
 *
 * Takes only element names, raw classes, and ids right now. Combines all given.
 */
function findParent(element, selector) {
    var matches = selector.match(/^([a-z0-9]*)(?:\.([a-z0-9-]+))?(?:#([a-z0-9-]+))?$/i);
    if (matches) {
        var selectorName = matches[1] || null;
        var selectorClass = matches[2] || null;
        var selectorId = matches[3] || null;
        
        var candidate = element;
        while (candidate) {
            do {
                if (selectorName && candidate.tagName && selectorName.toLowerCase() !== candidate.tagName.toLowerCase()) {
                    break;
                }
                if (selectorClass && !(candidate.classList && candidate.classList.contains(selectorClass))) {
                    break;
                }
                if (selectorId && selectorId !== candidate.id) {
                    break;
                }
                return candidate;
            } while (false);
            candidate = candidate.parentNode;
        }
    } else {
        throw new Error("Unexpected findParent selector format: " + selector);
    }
    return null;
}

document.onclick = function() {
    // Reminder: resist adding any click/tap handling here - they can
    // "fight" with items in the touchEndedWithoutDragging handler.
    // Add click/tap handling to touchEndedWithoutDragging instead.
    event.preventDefault(); // <-- Do not remove!
}

touchDownY = 0.0;
function touchStart(event){
    touchDownY = parseInt(event.changedTouches[0].clientY);
}
document.addEventListener("touchstart", touchStart, "false");

function handleTouchEnded(event){
    var touchobj = event.changedTouches[0];
    touchEndY = parseInt(touchobj.clientY);
    if (((touchDownY - touchEndY) == 0) && (event.changedTouches.length == 1)) {
        // None of our tap events should fire if the user dragged the page at all.
        touchEndedWithoutDragging(event);
    }
}

function touchEndedWithoutDragging(event){
    // Refactored to keep number of findParent calls to a minimum.
    var anchorTarget = findParent(event.target, 'A');
    var anchorTargetFound = anchorTarget && (anchorTarget.tagName === "A") ? true : false;

    // Handle A tag taps.
    if(anchorTargetFound){
        var href = anchorTarget.getAttribute( "href" );
        if (anchorTarget.getAttribute( "data-action" ) === "edit_section") {
            bridge.sendMessage( 'editClicked', { sectionId: anchorTarget.getAttribute( "data-id" ) });
        } else if ( refs.isReference( href ) ) {
            // Handle reference links with a popup view instead of scrolling about!
            refs.sendNearbyReferences( anchorTarget );
        } else if ( href[0] === "#" ) {
            // If it is a link to an anchor in the current page, just scroll to it
            document.getElementById( href.substring( 1 ) ).scrollIntoView();
        } else {
            bridge.sendMessage( 'linkClicked', { href: anchorTarget.getAttribute( "href" ) });
        }
    
    // Handle BUTTON tag taps.
    }else{
        var buttonTarget = findParent(event.target, 'BUTTON');
        var buttonTargetFound = buttonTarget && (buttonTarget.tagName === "BUTTON") ? true : false;
        if(buttonTargetFound){
            if (buttonTarget.id === "mw-language-button") {
                bridge.sendMessage( 'langClicked', {} );
            }else if (buttonTarget.id === "mw-last-modified") {
                bridge.sendMessage( 'historyClicked', {} );
            }
        }else{
            // Do NOT prevent default behavior -- this is needed to for instance
            // handle deselection of text.
            bridge.sendMessage( 'nonAnchorTouchEndedWithoutDragging', { id: event.target.getAttribute( "id" ), tagName: event.target.tagName});
        }
    }
}

document.addEventListener("touchend", handleTouchEnded, "false");

},{"./bridge":1,"./refs":5,"./transformer":6}],4:[function(require,module,exports){

var bridge = require("./bridge");
var elementLocation = require("./elementLocation");

window.bridge = bridge;
window.elementLocation = elementLocation;

},{"./bridge":1,"./elementLocation":2}],5:[function(require,module,exports){
var bridge = require("./bridge");

function isReference( href ) {
    return ( href.slice( 0, 10 ) === "#cite_note" );
}

function goDown( element ) {
    return element.getElementsByTagName( "A" )[0];
}

/**
 * Skip over whitespace but not other elements
 */
function skipOverWhitespace( skipFunc ) {
    return (function(element) {
        do {
            element = skipFunc( element );
            if (element && element.nodeType == Node.TEXT_NODE) {
                if (element.textContent.match(/^\s+$/)) {
                    // Ignore empty whitespace
                    continue;
                } else {
                    break;
                }
            } else {
                // found an element or ran out
                break;
            }
        } while (true);
        return element;
    });
}

var goLeft = skipOverWhitespace( function( element ) {
    return element.previousSibling;
});

var goRight = skipOverWhitespace( function( element ) {
    return element.nextSibling;
});

function hasReferenceLink( element ) {
    try {
        return isReference( goDown( element ).getAttribute( "href" ) );
    } catch (e) {
        return false;
    }
}

function collectRefText( sourceNode ) {
    var href = sourceNode.getAttribute( "href" );
    var targetId = href.slice(1);
    var targetNode = document.getElementById( targetId );
    if ( targetNode === null ) {
        console.log("reference target not found: " + targetId);
        return "";
    }

    // preferably without the back link
    var refTexts = targetNode.getElementsByClassName( "reference-text" );
    if ( refTexts.length > 0 ) {
        targetNode = refTexts[0];
    }

    return targetNode.innerHTML;
}

function collectRefLink( sourceNode ) {
    var node = sourceNode;
    while (!node.classList || !node.classList.contains('reference')) {
        node = node.parentNode;
        if (!node) {
            return '';
        }
    }
    return node.id;
}

function sendNearbyReferences( sourceNode ) {
    var refsIndex = 0;
    var refs = [];
    var linkId = [];
    var linkText = [];
    var curNode = sourceNode;

    // handle clicked ref:
    refs.push( collectRefText( curNode ) );
    linkId.push( collectRefLink( curNode ) );
    linkText.push( curNode.textContent );

    // go left:
    curNode = sourceNode.parentElement;
    while ( hasReferenceLink( goLeft( curNode ) ) ) {
        refsIndex += 1;
        curNode = goLeft( curNode );
        refs.unshift( collectRefText( goDown ( curNode ) ) );
        linkId.unshift( collectRefLink( curNode ) );
        linkText.unshift( curNode.textContent );
    }

    // go right:
    curNode = sourceNode.parentElement;
    while ( hasReferenceLink( goRight( curNode ) ) ) {
        curNode = goRight( curNode );
        refs.push( collectRefText( goDown ( curNode ) ) );
        linkId.push( collectRefLink( curNode ) );
        linkText.push( curNode.textContent );
    }

    // Special handling for references
    bridge.sendMessage( 'referenceClicked', {
        "refs": refs,
        "refsIndex": refsIndex,
        "linkId": linkId,
        "linkText": linkText
    } );
}

exports.isReference = isReference;
exports.sendNearbyReferences = sendNearbyReferences;

},{"./bridge":1}],6:[function(require,module,exports){
function Transformer() {
}

var transforms = {};

Transformer.prototype.register = function( transform, fun ) {
    if ( transform in transforms ) {
        transforms[transform].push( fun );
    } else {
        transforms[transform] = [ fun ];
    }
};

Transformer.prototype.transform = function( transform, element ) {
    var functions = transforms[transform];
    for ( var i = 0; i < functions.length; i++ ) {
        functions[i](element);
    }
};

module.exports = new Transformer();

},{}],7:[function(require,module,exports){
var transformer = require("./transformer");

transformer.register( "relocateInfobox", function( content ) {
    // Move infobox after first lead section paragraph.

    /*
    DIV section_heading_and_content_block_0
        DIV content_block_0
            P     <-- Move infobox after first P element which is a direct child of content_block_0 DIV.

    Old code had problem with en wiki "Soviet Union" article - it moved the 
    infobox right after a P element which was contained by a hidden "vcard" TABLE.
    */

    var block_0 = content.querySelector( "#content_block_0" );
    if(!block_0) return;

    var infobox = block_0.querySelector( "table.infobox" );
    if(!infobox) return;

    var allPs = block_0.querySelectorAll( "p" );
    if(!allPs) return;

    var soughtP = null;

    // Narrow down to first P which is direct child of content_block_0 DIV.
    for ( var i = 0; i < allPs.length; i++ ) {
        var thisP = allPs[i];
        if  (thisP.parentNode == block_0){
            soughtP = thisP;
            break;
        }
    }
    
    if (!soughtP) return;

    /*
    If the infobox table itself sits within a table or series of tables,
    move the most distant ancestor table instead of just moving the 
    infobox. Otherwise you end up with table(s) with a hole where the 
    infobox had been. World War II article on enWiki has this issue.
    Note that we need to stop checking ancestor tables when we hit
    content_block_0.
    */
    var infoboxParentTable = null;
    var el = infobox;
    while (el.parentNode) {
        el = el.parentNode;
        if (el.id === 'content_block_0') break;
        if (el.tagName === 'TABLE') infoboxParentTable = el;
    }
    if(infoboxParentTable)infobox = infoboxParentTable;

    // Found the first P tag whose direct parent has id of #content_block_0.
    // Now safe to detach the infobox and stick it after the P.
    soughtP.appendChild(infobox.parentNode.removeChild(infobox));
});

transformer.register( "hideRedlinks", function( content ) {
	var redLinks = content.querySelectorAll( 'a.new' );
	for ( var i = 0; i < redLinks.length; i++ ) {
		var redLink = redLinks[i];
        redLink.style.color = 'inherit';
	}
} );

transformer.register( "disableFilePageEdit", function( content ) {
    var filetoc = content.querySelector( '#filetoc' );
    if (filetoc) {
        // We're on a File: page! Do some quick hacks.
        // In future, replace entire thing with a custom view most of the time.
        // Hide edit sections
        var editSections = content.querySelectorAll('.edit_section_button');
        for (var i = 0; i < editSections.length; i++) {
            editSections[i].style.display = 'none';
        }
        var fullImageLink = content.querySelector('.fullImageLink a');
        if (fullImageLink) {
            // Don't replace the a with a span, as it will break styles.
            // Just disable clicking.
            // Don't disable touchstart as this breaks scrolling!
            fullImageLink.href = '';
            fullImageLink.addEventListener( 'click', function( event ) {
                event.preventDefault();
            } );
        }
    }
} );


},{"./transformer":6}]},{},[1,2,3,4,5,6,7])