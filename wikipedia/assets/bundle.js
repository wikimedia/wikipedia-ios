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
    var url = "x-wikipedia-bridge:" + JSON.stringify( messagePack );
    
    // quick iframe version based on http://stackoverflow.com/a/6508343/82439
    // fixme can this be an XHR instead? check Cordova current state
    var iframe = document.createElement('iframe');
    iframe.setAttribute("src", url);
    document.documentElement.appendChild(iframe);
    iframe.parentNode.removeChild(iframe);
    iframe = null;
};

module.exports = new Bridge();

// FIXME: Move this to somwehere else, eh?
window.onload = function() {
    module.exports.sendMessage( "DOMLoaded", {} );
};

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
var wikihacks = require("./wikihacks");

//TODO: move makeTablesNotBlockIfSafeToDoSo, hideAudioTags and reduceWeirdWebkitMargin out into own js object.

bridge.registerListener( "setLanguage", function( payload ){
    var body = document.querySelector( "body" );
    body.lang = payload.lang;
    body.dir = payload.dir;
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

bridge.registerListener( "append", function( payload ) {
                        console.log('hello append');
    // Append html without losing existing event handlers
    // From: http://stackoverflow.com/a/595825
    var content = document.getElementById("content");
    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;

    while (newcontent.firstChild) {
// Quite often this pushes the first image pretty far offscreen... hmmm...
//      newcontent.firstChild = transforms.transform( "lead", newcontent.firstChild );
        content.appendChild(newcontent.firstChild);
    }
    // Things which need to happen any time data is appended.
    //TODO: later could optimize to only perform actions on elements found
    // within the content div which was appended).

    wikihacks.putWideTablesInDivs();
/*
    wikihacks.makeTablesNotBlockIfSafeToDoSo();
    wikihacks.reduceWeirdWebkitMargin();
 */
    wikihacks.hideAudioTags();
/*
    wikihacks.allowDivWidthsToFlow();
*/
    wikihacks.hideRedLinks();
    wikihacks.tweakFilePage();
});

bridge.registerListener( "prepend", function( payload ) {
    // Prepend html without losing existing event handlers
    var content = document.getElementById("content");
    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;
    content.insertBefore(newcontent, content.firstChild);
});

bridge.registerListener( "remove", function( payload ) {
    document.getElementById( "content" ).removeChild(document.getElementById(payload.element));
});

bridge.registerListener( "clear", function( payload ) {
    document.getElementById( "content" ).innerHTML = '';
});

bridge.registerListener( "ping", function( payload ) {
    bridge.sendMessage( "pong", payload );
});

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

    /*
    If the clicked object was not an anchor, the object may have been
    an html tag styling the anchor text, such as the bold tags in the
    following:

    <a href="/wiki/Castlevania:_Aria_of_Sorrow" title="Castlevania: Aria of Sorrow"><b>Full article...</b></a>

    To handle these cases just walk ancestors until an anchor tag is
    encountered.
    */

    var anchorTarget = findParent(event.target, 'A');

    if ( anchorTarget && (anchorTarget.tagName === "A") ) {
        var href = anchorTarget.getAttribute( "href" );
        if ( href[0] === "#" ) {
            // If it is a link to an anchor in the current page, just scroll to it
            document.getElementById( href.substring( 1 ) ).scrollIntoView();
        } else {
            bridge.sendMessage( 'linkClicked', { href: anchorTarget.getAttribute( "href" ) });
        }
    }
    event.preventDefault();
}

touchDownY = 0.0;
function touchStart(event){
    touchDownY = parseInt(event.changedTouches[0].clientY);
}
document.addEventListener("touchstart", touchStart, "false");

function touchEnd(event){
    var touchobj = event.changedTouches[0];
    touchEndY = parseInt(touchobj.clientY);
    if (((touchDownY - touchEndY) == 0) && (event.changedTouches.length == 1)) {
        if (event.target.tagName === "A") {
            if (event.target.className === "edit_section_button") {
                bridge.sendMessage( 'editClicked', { sectionId: event.target.getAttribute( "data-id" ) });
            }
        } else if (findParent(event.target, 'button.mw-language-button')) {
            bridge.sendMessage( 'langClicked', {} );
        } else if (findParent(event.target, 'button.mw-last-modified')) {
            bridge.sendMessage( 'historyClicked', {} );
        } else {
            var anchorTarget = findParent(event.target, 'A');
            if ( anchorTarget && (anchorTarget.tagName != "A") ) {
                event.preventDefault();
                bridge.sendMessage( 'nonAnchorTouchEndedWithoutDragging', { id: event.target.getAttribute( "id" ), tagName: event.target.tagName});
            }
        }
    }
}

document.addEventListener("touchend", touchEnd, "false");

},{"./bridge":1,"./wikihacks":5}],4:[function(require,module,exports){

var bridge = require("./bridge");
var elementLocation = require("./elementLocation");

window.bridge = bridge;
window.elementLocation = elementLocation;

},{"./bridge":1,"./elementLocation":2}],5:[function(require,module,exports){

// this doesn't seem to work on iOS?
exports.makeTablesNotBlockIfSafeToDoSo = function() {
    // Tables which are narrower than their container look funny - this is caused by table
    // css 'display' being set to 'block'. But this *is needed* when the table content is
    // wider than the table's container. So conditionally set table display to 'table' if
    // the table isn't as wide as its container. Result: things which need horizontal
    // overflow scrolling still can do so, but things which don't need to scroll look
    // so much better. (See the "San Francisco" article with and without this method for
    // comparison.)
    var tbodies = document.getElementsByTagName('TBODY');
    for (var i = 0; i < tbodies.length; ++i) {
        var tbody = tbodies[i];
        var tbodyRect = tbody.getBoundingClientRect();
        var parentRect = tbody.parentElement.getBoundingClientRect();
        //var style = window.getComputedStyle(tbody);
        if(tbodyRect.width < parentRect.width){
            tbody.parentElement.style.float = "";
            tbody.parentElement.style.margin = "";
            tbody.parentElement.style.display = 'table';
        }
    }
}

// this *does* seem to work on ios
// wrap wide tables in a <div style="overflow-x:auto">...</div>
exports.putWideTablesInDivs = function() {
    var tbodies = document.getElementsByTagName('TBODY');
    for (var i = 0; i < tbodies.length; ++i) {
        var tbody = tbodies[i];
        var tbodyRect = tbody.getBoundingClientRect();
        var parentRect = tbody.parentElement.getBoundingClientRect(); // this doesn't give a useful result, as parent is sized to the table?
        //if(tbodyRect.width >= parentRect.width){
            var table = tbody.parentElement;
            var parent = table.parentElement;
            var div = document.createElement( 'div' );
            div.style.overflowX = 'auto';
            parent.insertBefore( div, table );
            var oldTable = parent.removeChild( table );
            div.appendChild( oldTable );
        //}
    }
}


exports.reduceWeirdWebkitMargin = function() {
    // See the "Tuna" article for tables having weird left margin. This removes it.
    var dds = document.getElementsByTagName('DD');
    for (var i = 0; i < dds.length; ++i) {
        dds[i].style["-webkit-margin-start"] = "1px";
    }
}

exports.allowDivWidthsToFlow = function() {
    // See the "San Francisco" article for divs having weird margin issues. This fixes.
    var divs = document.getElementsByTagName('div');
    for (var i = 0; i < divs.length; ++i) {
        divs[i].style.width = "";
    }
}

exports.hideAudioTags = function() {
    // The audio tag can't be completely hidden in css for some reason - need to clear its
    // "controls" attribute for it to not display a "could not play audio" grey box.
    var audio = document.getElementsByTagName('AUDIO');
    for (var i = 0; i < audio.length; ++i) {
        var thisAudio = audio[i];
        thisAudio.controls = '';
        thisAudio.style.display = 'none';
    }
}

exports.hideRedLinks = function() {
    var redLinks = document.querySelectorAll( 'a.new' );
    for ( var i = 0; i < redLinks.length; i++ ) {
        var redLink = redLinks[i];
        var replacementSpan = document.createElement( 'span' );
        replacementSpan.innerHTML = redLink.innerHTML;
        replacementSpan.setAttribute( 'class', redLink.getAttribute( 'class' ) );
        redLink.parentNode.replaceChild( replacementSpan, redLink );
    }
}

exports.tweakFilePage = function() {
    var filetoc = document.getElementById( 'filetoc' );
    if (filetoc) {
        // We're on a File: page! Do some quick hacks.
        // In future, replace entire thing with a custom view most of the time.
        var content = document.getElementById( 'content' );
        
        // Hide edit sections
        var editSections = content.querySelectorAll('.edit_section_button');
        for (var i = 0; i < editSections.length; i++) {
            editSections[i].style.display = 'none';
        }
        
        var fullImageLink = content.querySelector('.fullImageLink a');
        if (fullImageLink) {
            // Don't replace the a with a span, as it will break styles
            // Just disable clicking.
            // Don't disable touchstart as this breaks scrolling!
            fullImageLink.href = '';
            fullImageLink.addEventListener( 'click', function( event ) {
                event.preventDefault();
            } );
        }
    }
}

},{}]},{},[1,2,3,4,5])