(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);throw new Error("Cannot find module '"+o+"'")}var f=n[o]={exports:{}};t[o][0].call(f.exports,function(e){var n=t[o][1][e];return s(n?n:e)},f,f.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
(function (module) {

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

})(module);

},{}],2:[function(require,module,exports){
//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
}

function getZoomLevel() {
    // From: http://stackoverflow.com/a/5078596/135557
    var deviceWidth = (Math.abs(window.orientation) === 90) ? screen.height : screen.width;
    var zoom = deviceWidth / window.innerWidth;
    return zoom;
}

exports.getImageWithSrc = function(src) {
    var images = document.getElementsByTagName('img');
    for (var i = 0; i < images.length; ++i) {
        if (stringEndsWith(images[i].src, src)) {
            return images[i];
        }
    }
    return null;
};

exports.getElementRect = function(element) {
    var rect = element.getBoundingClientRect();
    var zoom = getZoomLevel();
    var zoomedRect = {
        top: rect.top * zoom,
        left: rect.left * zoom,
        width: rect.width * zoom,
        height: rect.height * zoom
    };
    return zoomedRect;
};

exports.getElementRectAsJson = function(element) {
    return JSON.stringify(this.getElementRect(element));
};

exports.getIndexOfFirstOnScreenElementWithTopGreaterThanY = function(elementPrefix, elementCount){
    for (var i = 0; i < elementCount; ++i) {
        var div = document.getElementById(elementPrefix + i);
        if (div === null) {
            continue;
        }
        var rect = this.getElementRect(div);
        if ( (rect.top >= 0) || ((rect.top + rect.height) >= 0)) {
            return i;
        }
    }
    return -1;
};

},{}],3:[function(require,module,exports){
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
        /*global console */
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

transformer.register( "moveFirstGoodParagraphUp", function( content ) {
    /*
    Instead of moving the infobox down beneath the first P tag,
    move the first good looking P tag *up* (as the first child of
    the first section div). That way the first P text will appear not
    only above infoboxes, but above other tables/images etc too!
    */

    if(content.getElementById( "mainpage" ))return;

    var block_0 = content.getElementById( "content_block_0" );
    if(!block_0) return;

    var allPs = block_0.getElementsByTagName( "p" );
    if(!allPs) return;

    var edit_section_button_0 = content.getElementById( "edit_section_button_0" );
    if(!edit_section_button_0) return;

    function moveAfter(newNode, referenceNode) {
        // Based on: http://stackoverflow.com/a/4793630/135557
        referenceNode.parentNode.insertBefore(newNode.parentNode.removeChild(newNode), referenceNode.nextSibling);
    }

    for ( var i = 0; i < allPs.length; i++ ) {
        var p = allPs[i];

        // Narrow down to first P which is direct child of content_block_0 DIV.
        // (Don't want to yank P from somewhere in the middle of a table!)
        if  (p.parentNode != block_0) continue;


        // Ensure the P being pulled up has at least a couple lines of text.
        // Otherwise silly things like a empty P or P which only contains a
        // BR tag will get pulled up (see articles on "Chemical Reaction" and
        // "Hawaii").
        // Trick for quickly determining element height:
        //      https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement.offsetHeight
        //      http://stackoverflow.com/a/1343350/135557
        var minHeight = 40;
        var pIsTooSmall = (p.offsetHeight < minHeight);
        if(pIsTooSmall) continue;


        /*
        // Note: this works - just not sure if needed?
        // Sometimes P will be mostly image and not much text. Don't
        // want to move these!
        var pIsMostlyImage = false;
        var imgs = p.getElementsByTagName('img');
        for (var j = 0; j < imgs.length; j++) {
            var thisImg = imgs[j];
            // Get image height from img tag's height attribute - otherwise
            // you'd have to wait for the image to render (if you used offsetHeight).
            var thisImgHeight = thisImg.getAttribute("height");
            if(thisImgHeight == 0) continue;
            var imgHeightPercentOfParagraphTagHeight = thisImgHeight / p.offsetHeight;
            if (imgHeightPercentOfParagraphTagHeight > 0.5){
                pIsMostlyImage = true;
                break;
            }
        }
        if(pIsMostlyImage) continue;
        */

        // Move the P! Place it just after the lead section edit button.
        moveAfter(p, edit_section_button_0);

        // But only move one P!
        break;
    }
});

/*
Tries to get an array of table header (TH) contents from a given table.
If there are no TH elements in the table, an empty array is returned.
*/
function getTableHeader( element ) {
    var thArray = [];
    if (element.children === undefined || element.children === null) {
        return thArray;
    }
    for (var i = 0; i < element.children.length; i++) {
        var el = element.children[i];
        if (el.tagName === "TH") {
            // ok, we have a TH element!
            // However, if it contains more than two links, then ignore it, because
            // it will probably appear weird when rendered as plain text.
            var aNodes = el.querySelectorAll( "a" );
            if (aNodes.length < 3) {
                // Also ignore it if it's identical to the page title.
                if (el.innerText.length > 0 && el.innerText !== window.pageTitle && el.innerHTML !== window.pageTitle) {
                    thArray.push(el.innerText);
                }
            }
        }
        //if it's a table within a table, don't worry about it
        if (el.tagName === "TABLE") {
            continue;
        }
        //recurse into children of this element
        var ret = getTableHeader(el);
        //did we get a list of TH from this child?
        if (ret.length > 0) {
            thArray = thArray.concat(ret);
        }
    }
    return thArray;
}

/*
OnClick handler function for expanding/collapsing tables and infoboxes.
*/
function tableCollapseClickHandler() {
    var container = this.parentNode;
    var divCollapsed = container.children[0];
    var tableFull = container.children[1];
    var divBottom = container.children[2];
    if (tableFull.style.display !== 'none') {
        tableFull.style.display = 'none';
        divCollapsed.classList.remove('app_table_collapse_close');
        divCollapsed.classList.remove('app_table_collapse_icon');
        divCollapsed.classList.add('app_table_collapsed_open');
        divBottom.style.display = 'none';
        //if they clicked the bottom div, then scroll back up to the top of the table.
        if (this === divBottom) {
            window.scrollTo( 0, container.offsetTop - 48 );
        }
    } else {
        tableFull.style.display = 'block';
        divCollapsed.classList.remove('app_table_collapsed_open');
        divCollapsed.classList.add('app_table_collapse_close');
        divCollapsed.classList.add('app_table_collapse_icon');
        divBottom.style.display = 'block';
    }
}

transformer.register( "addImageOverflowXContainers", function( content ) {
    // Wrap images in a <div style="overflow-x:auto">...</div> so they can scroll side
    // to side if needed without causing the entire section to scroll side to side.
    var images = content.querySelectorAll('img');
    for (var i = 0; i < images.length; ++i) {
        var image = images[i];
        var parent = image.parentElement;
        var div = document.createElement( 'div' );
        div.className = 'image_overflow_x_container';
        parent.insertBefore( div, image );
        var oldImage = parent.removeChild( image );
        div.appendChild( oldImage );
    }
} );

// From: http://stackoverflow.com/a/22119674/135557
function findAncestor (el, cls) {
    while ((el = el.parentElement) && !el.classList.contains(cls));
    return el;
}

transformer.register( "hideTables", function( content ) {
    var tables = content.querySelectorAll( "table" );
    for (var i = 0; i < tables.length; i++) {

        if (findAncestor (tables[i], 'app_table_container')) continue;

        //is the table already hidden? if so, don't worry about it
        if (tables[i].style.display === 'none' || tables[i].classList.contains( 'navbox' ) || tables[i].classList.contains( 'vertical-navbox' ) || tables[i].classList.contains( 'navbox-inner' ) || tables[i].classList.contains( 'metadata' )) {
            continue;
        }

        var isInfobox = tables[i].classList.contains( 'infobox' );
        
        var parent = tables[i].parentElement;

        // If parent contains only this table it's safe to reset its styling
        if (parent.childElementCount === 1){
            parent.removeAttribute("class");
            parent.removeAttribute("style");
        }

        // Remove max width restriction
        tables[i].style.maxWidth = 'none';

        var headerText = getTableHeader(tables[i]);

        var caption = "<strong>" + (isInfobox ? window.string_table_infobox : window.string_table_other) + "</strong>";
        caption += "<span class='app_span_collapse_text'>";
        if (headerText.length > 0) {
            caption += ": " + headerText[0];
        }
        if (headerText.length > 1) {
            caption += ", " + headerText[1];
        }
        if (headerText.length > 0) {
            caption += ", ...";
        }
        caption += "</span>";

        //create the container div that will contain both the original table
        //and the collapsed version.
        var containerDiv = document.createElement( 'div' );
        containerDiv.className = 'app_table_container';
        tables[i].parentNode.insertBefore(containerDiv, tables[i]);
        tables[i].parentNode.removeChild(tables[i]);

        //remove top and bottom margin from the table, so that it's flush with
        //our expand/collapse buttons
        tables[i].style.marginTop = "0px";
        tables[i].style.marginBottom = "0px";

        //create the collapsed div
        var collapsedDiv = document.createElement( 'div' );
        collapsedDiv.classList.add('app_table_collapsed_container');
        collapsedDiv.classList.add('app_table_collapsed_open');
        collapsedDiv.innerHTML = caption;

        //create the bottom collapsed div
        var bottomDiv = document.createElement( 'div' );
        bottomDiv.classList.add('app_table_collapsed_bottom');
        bottomDiv.classList.add('app_table_collapse_icon');
        bottomDiv.innerHTML = window.string_table_close;

        //add our stuff to the container
        containerDiv.appendChild(collapsedDiv);
        containerDiv.appendChild(tables[i]);
        containerDiv.appendChild(bottomDiv);

        //set initial visibility
        tables[i].style.display = 'none';
        collapsedDiv.style.display = 'block';
        bottomDiv.style.display = 'none';

        //assign click handler to the collapsed divs
        collapsedDiv.onclick = tableCollapseClickHandler;
        bottomDiv.onclick = tableCollapseClickHandler;
    }
} );


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