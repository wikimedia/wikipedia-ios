(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var wmf = {};

wmf.elementLocation = require("./js/elementLocation");
wmf.transformer = require("./js/transformer");
wmf.utilities = require("./js/utilities");

window.wmf = wmf;
},{"./js/elementLocation":2,"./js/transformer":5,"./js/utilities":12}],2:[function(require,module,exports){
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
    // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
    var zoomedRect = {
        Y: rect.top * zoom,
        X: rect.left * zoom,
        Width: rect.width * zoom,
        Height: rect.height * zoom
    };
    return zoomedRect;
};

exports.getIndexOfFirstOnScreenElement = function(elementPrefix, elementCount){
    for (var i = 0; i < elementCount; ++i) {
        var div = document.getElementById(elementPrefix + i);
        if (div === null) {
            continue;
        }
        var rect = this.getElementRect(div);
        if ( (rect.Y >= -1) || ((rect.Y + rect.Height) >= 50)) {
            return i;
        }
    }
    return -1;
};

exports.getElementFromPoint = function(x, y){
    return document.elementFromPoint(x - window.pageXOffset, y - window.pageYOffset);
};

},{}],3:[function(require,module,exports){
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
                                                          'height': (event.target.naturalHeight / window.devicePixelRatio),
 														  'data-file-width': event.target.getAttribute('data-file-width'),
 														  'data-file-height': event.target.getAttribute('data-file-height')
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
                           var element = window.wmf.elementLocation.getElementFromPoint(event.changedTouches[0].pageX, event.changedTouches[0].pageY);
                           window.webkit.messageHandlers.peek.postMessage({"peekElement": {
                                                                          'tagName': element.tagName,
                                                                          'href': element.href,
                                                                          'src': element.src
                                                                          }});
                           }, false);
 
 document.addEventListener("touchend", function () {
                           // Tell native land to clear the url - important.
                           window.webkit.messageHandlers.peek.postMessage({"peekElement": null});
                           }, false);
})();

},{"./refs":4,"./utilities":12}],4:[function(require,module,exports){

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
    window.webkit.messageHandlers.clicks.postMessage({"referenceClicked": {
                                                     "refs": refs,
                                                     "refsIndex": refsIndex,
                                                     "linkId": linkId,
                                                     "linkText": linkText
                                                     }});
}

exports.isReference = isReference;
exports.sendNearbyReferences = sendNearbyReferences;

},{}],5:[function(require,module,exports){
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

Transformer.prototype.transform = function( transform ) {
    var functions = transforms[transform];
    for ( var i = 0; i < functions.length; i++ ) {
        functions[i](arguments[1], arguments[2], arguments[3], arguments[4], arguments[5], arguments[6], arguments[7], arguments[8], arguments[9], arguments[10]);
    }
};

module.exports = new Transformer();

},{}],6:[function(require,module,exports){
var transformer = require("../transformer");
var utilities = require("../utilities");

function shouldAddImageOverflowXContainer(image) {
    if ((image.width > (window.screen.width * 0.8)) && !utilities.isNestedInTable(image)){
        return true;
    }else{
        return false;
    }
}

function addImageOverflowXContainer(image, ancestor) {
    image.setAttribute('hasOverflowXContainer', 'true'); // So "widenImages" transform knows instantly not to widen this one.
    var div = document.createElement( 'div' );
    div.className = 'image_overflow_x_container';
    ancestor.parentElement.insertBefore( div, ancestor );
    div.appendChild( ancestor );
}

function firstAncestorWithMultipleChildren (el) {
    while ((el = el.parentElement) && (el.childElementCount == 1));
    return el;
}

function maybeAddImageOverflowXContainer() {
    var image = this;
    if (shouldAddImageOverflowXContainer(image)){
        var ancestor = firstAncestorWithMultipleChildren (image);
        if(ancestor){
            addImageOverflowXContainer(image, ancestor);
        }
    }
}

transformer.register( "addImageOverflowXContainers", function( content ) {
    // Wrap wide images in a <div style="overflow-x:auto">...</div> so they can scroll
    // side to side if needed without causing the entire section to scroll side to side.
    var images = content.getElementsByTagName('img');
    for (var i = 0; i < images.length; ++i) {
        // Load event used so images w/o style or inline width/height
        // attributes can still have their size determined reliably.
        images[i].addEventListener('load', maybeAddImageOverflowXContainer, false);
    }
} );

},{"../transformer":5,"../utilities":12}],7:[function(require,module,exports){
var transformer = require("../transformer");
var utilities = require("../utilities");

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

function shouldTableBeCollapsed( table ) {
    if (table.style.display === 'none' ||
        table.classList.contains( 'navbox' ) ||
        table.classList.contains( 'vertical-navbox' ) ||
        table.classList.contains( 'navbox-inner' ) ||
        table.classList.contains( 'metadata' ) ||
        table.classList.contains( 'mbox-small' )) {
        return false;
    }
    return true;
}

transformer.register( "hideTables", function( content , isMainPage, titleInfobox, titleOther, titleClose) {
    if (isMainPage == "1") return;
                     
    var tables = content.querySelectorAll( "table" );
    for (var i = 0; i < tables.length; i++) {
        var table = tables[i];
        if (utilities.findClosest (table, '.app_table_container')) continue;

        if (!shouldTableBeCollapsed(table)) {
            continue;
        }

        var isInfobox = table.classList.contains( 'infobox' );
        
        var parent = table.parentElement;

        // If parent contains only this table it's safe to reset its styling
        if (parent.childElementCount === 1){
            parent.removeAttribute("class");
            parent.removeAttribute("style");
        }

        // Remove max width restriction
        table.style.maxWidth = 'none';

        var headerText = getTableHeader(table);

        var caption = "<strong>" + (isInfobox ? titleInfobox : titleOther) + "</strong>";
        caption += "<span class='app_span_collapse_text'>";
        if (headerText.length > 0) {
            caption += ": " + headerText[0];
        }
        if (headerText.length > 1) {
            caption += ", " + headerText[1];
        }
        if (headerText.length > 0) {
            caption += " ...";
        }
        caption += "</span>";

        //create the container div that will contain both the original table
        //and the collapsed version.
        var containerDiv = document.createElement( 'div' );
        containerDiv.className = 'app_table_container';
        table.parentNode.insertBefore(containerDiv, table);
        table.parentNode.removeChild(table);

        //remove top and bottom margin from the table, so that it's flush with
        //our expand/collapse buttons
        table.style.marginTop = "0px";
        table.style.marginBottom = "0px";

        //create the collapsed div
        var collapsedDiv = document.createElement( 'div' );
        collapsedDiv.classList.add('app_table_collapsed_container');
        collapsedDiv.classList.add('app_table_collapsed_open');
        collapsedDiv.innerHTML = caption;

        //create the bottom collapsed div
        var bottomDiv = document.createElement( 'div' );
        bottomDiv.classList.add('app_table_collapsed_bottom');
        bottomDiv.classList.add('app_table_collapse_icon');
        bottomDiv.innerHTML = "<strong>" + titleClose + "</strong>";

        //add our stuff to the container
        containerDiv.appendChild(collapsedDiv);
        containerDiv.appendChild(table);
        containerDiv.appendChild(bottomDiv);

        //set initial visibility
        table.style.display = 'none';
        collapsedDiv.style.display = 'block';
        bottomDiv.style.display = 'none';

        //assign click handler to the collapsed divs
        collapsedDiv.onclick = tableCollapseClickHandler;
        bottomDiv.onclick = tableCollapseClickHandler;
    }
} );

},{"../transformer":5,"../utilities":12}],8:[function(require,module,exports){
var transformer = require("../transformer");

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

},{"../transformer":5}],9:[function(require,module,exports){
var transformer = require("../transformer");

transformer.register( "hideRedlinks", function( content ) {
	var redLinks = content.querySelectorAll( 'a.new' );
	for ( var i = 0; i < redLinks.length; i++ ) {
		var redLink = redLinks[i];
        redLink.style.color = 'inherit';
	}
} );

},{"../transformer":5}],10:[function(require,module,exports){
var transformer = require("../transformer");

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

    function isParagraphGood(p) {
        // Narrow down to first P which is direct child of content_block_0 DIV.
        // (Don't want to yank P from somewhere in the middle of a table!)
        if  ((p.parentNode == block_0) ||
            /* HAX: the line below is a temporary fix for <div class="mw-mobilefrontend-leadsection"> temporarily
               leaking into mobileview output - as soon as that div is removed the line below will no longer be needed. */
            (p.parentNode.className == "mw-mobilefrontend-leadsection")
            ){
                // Ensure the P being pulled up has at least a couple lines of text.
                // Otherwise silly things like a empty P or P which only contains a
                // BR tag will get pulled up (see articles on "Chemical Reaction" and
                // "Hawaii").
                // Trick for quickly determining element height:
                //      https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement.offsetHeight
                //      http://stackoverflow.com/a/1343350/135557
                var minHeight = 40;
                var pIsTooSmall = (p.offsetHeight < minHeight);
                return !pIsTooSmall;
            }else{
                return false;
            }
    }
 
    var firstGoodParagraph = function(){
        return Array.prototype.slice.call( allPs).find(isParagraphGood);
    }();

    if(!firstGoodParagraph) return;

    // Move everything between the firstGoodParagraph and the next paragraph to a light-weight fragment.
    var fragmentOfItemsToRelocate = function(){
        var didHitGoodP = false;
        var didHitNextP = false;

        var shouldElementMoveUp = function(element) {
            if(didHitGoodP && element.tagName === 'P'){
                didHitNextP = true;
            }else if(element.isEqualNode(firstGoodParagraph)){
                didHitGoodP = true;
            }
            return (didHitGoodP && !didHitNextP);
        };

        var fragment = document.createDocumentFragment();
        Array.prototype.slice.call(firstGoodParagraph.parentNode.childNodes).forEach(function(element) {
            if(shouldElementMoveUp(element)){
                // appendChild() attaches the element to the fragment *and* removes it from DOM.
                fragment.appendChild(element);
            }
        });
        return fragment;
    }();

    // Attach the fragment just after the lead section edit button.
    // insertBefore() on a fragment inserts "the children of the fragment, not the fragment itself."
    // https://developer.mozilla.org/en-US/docs/Web/API/DocumentFragment
    block_0.insertBefore(fragmentOfItemsToRelocate, edit_section_button_0.nextSibling);
});

},{"../transformer":5}],11:[function(require,module,exports){
var transformer = require("../transformer");
var utilities = require("../utilities");

var maxStretchRatioAllowedBeforeRequestingHigherResolution = 1.3;

// If enabled, widened images will have thin red dashed border and
// and widened images for which a higher resolution version was
// requested will have thick red dashed border.
var enableDebugBorders = false;

function widenAncestors (el) {
    while ((el = el.parentElement) && !el.classList.contains('content_block')){
        // Only widen if there was a width setting. Keeps changes minimal.
        if(el.style.width){
            el.style.width = '100%';
        }
        if(el.style.maxWidth){
            el.style.maxWidth = '100%';
        }
        if(el.style.float){
            el.style.float = 'none';
        }
    }
}

function shouldWidenImage(image) {
    if (
        image.width >= 64 &&
        image.hasAttribute('data-file-width') &&
        !image.hasAttribute('hasOverflowXContainer') &&
        !utilities.isNestedInTable(image)
        ) {
        return true;
    }else{
        return false;
    }
}

function makeRoomForImageWidening(image) {
    // Expand containment so css wideImageOverride width percentages can take effect.
    widenAncestors (image);

    // Remove width and height attributes so wideImageOverride width percentages can take effect.
    image.removeAttribute("width");
    image.removeAttribute("height");
}

function firstDivAncestor (el) {
    while ((el = el.parentElement)){
        if(el.tagName === 'DIV'){
            return el;
        }
    }
    return null;
}

function getStretchRatio(image){
    var widthControllingDiv = firstDivAncestor(image);
    if (widthControllingDiv){
        return (widthControllingDiv.offsetWidth / image.naturalWidth);
    }
    return 1.0;
}

function useHigherResolutionImageSrcIfNecessary(image) {
    var src = image.getAttribute('src');
	var resized = image.getAttribute('data-image-resized');
    if (resized !== "true" && src){
        var stretchRatio = getStretchRatio(image);
        if (stretchRatio > maxStretchRatioAllowedBeforeRequestingHigherResolution) {
			var pathComponents = src.split("/");
			var filename = pathComponents[pathComponents.length - 1];
			var sizeRegex = /^[0-9]+(?=px-)/;
			var sizeMatches = filename.match(sizeRegex);
			if (sizeMatches.length > 0) {
				var size = parseInt(sizeMatches[0]);
				var originalSize = parseInt(image.getAttribute('data-file-width'));
				var newSize = window.devicePixelRatio < 2 ? 320 : 640; //actual width is size*stretchRatio*window.devicePixelRatio;
				var newSrc = pathComponents.slice(0,-1).join('/');
				if (newSize < originalSize) {
					var newFilename = filename.replace(sizeRegex, newSize.toString());
					newSrc = newSrc + '/' + newFilename;
				} else if (filename.toLowerCase().indexOf('.svg') == -1) {
					newSrc = newSrc.replace('/thumb/', '/');
				}
				image.src = newSrc;
	            if(enableDebugBorders){
	                image.style.borderWidth = '10px';
	            }
			}
        } 
    }
}

function widenImage(image) {
    makeRoomForImageWidening (image);
    image.classList.add("wideImageOverride");

    if(enableDebugBorders){
        image.style.borderStyle = 'dashed';
        image.style.borderWidth = '1px';
        image.style.borderColor = '#f00';
    }

    useHigherResolutionImageSrcIfNecessary(image);
}

function maybeWidenImage() {
    var image = this;
    image.removeEventListener('load', maybeWidenImage, false);
    if (shouldWidenImage(image)) {
        widenImage(image);
    }
}

transformer.register( "widenImages", function( content ) {
    var images = content.querySelectorAll( 'img' );
    for ( var i = 0; i < images.length; i++ ) {
        // Load event used so images w/o style or inline width/height
        // attributes can still have their size determined reliably.
        images[i].addEventListener('load', maybeWidenImage, false);
    }
} );

},{"../transformer":5,"../utilities":12}],12:[function(require,module,exports){

// Implementation of https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
function findClosest (el, selector) {
    while ((el = el.parentElement) && !el.matches(selector));
    return el;
}

function isNestedInTable(el) {
    while ((el = el.parentElement)){
        if(el.tagName === 'TD'){
            return true;
        }
    }
    return false;
}

function setLanguage(lang, dir, uidir){
    var html = document.querySelector( "html" );
    html.lang = lang;
    html.dir = dir;
    html.classList.add( 'content-' + dir );
    html.classList.add( 'ui-' + uidir );
    document.querySelector('base').href = 'https://' + lang + '.wikipedia.org/';
}

function setPageProtected(){
    document.getElementsByTagName( "html" )[0].classList.add( "page-protected" );
}

function scrollToFragment(fragmentId){
    location.hash = '';
    location.hash = fragmentId;
}

function accessibilityCursorToFragment(fragmentId){
    /* Attempt to move accessibility cursor to fragment. We need to /change/ focus,
     in order to have the desired effect, so we first give focus to the body element,
     then move it to the desired fragment. */
    var focus_element = document.getElementById(fragmentId);
    var other_element = document.body;
    other_element.setAttribute('tabindex', 0);
    other_element.focus();
    focus_element.setAttribute('tabindex', 0);
    focus_element.focus();
}

exports.accessibilityCursorToFragment = accessibilityCursorToFragment;
exports.scrollToFragment = scrollToFragment;
exports.setPageProtected = setPageProtected;
exports.setLanguage = setLanguage;
exports.findClosest = findClosest;
exports.isNestedInTable = isNestedInTable;

},{}]},{},[1,2,3,4,5,6,7,8,9,10,11,12]);
