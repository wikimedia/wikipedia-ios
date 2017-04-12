(function e(t,n,r){function s(o,u){if(!n[o]){if(!t[o]){var a=typeof require=="function"&&require;if(!u&&a)return a(o,!0);if(i)return i(o,!0);var f=new Error("Cannot find module '"+o+"'");throw f.code="MODULE_NOT_FOUND",f}var l=n[o]={exports:{}};t[o][0].call(l.exports,function(e){var n=t[o][1][e];return s(n?n:e)},l,l.exports,e,t,n,r)}return n[o].exports}var i=typeof require=="function"&&require;for(var o=0;o<r.length;o++)s(r[o]);return s})({1:[function(require,module,exports){
var wmf = {};

wmf.elementLocation = require("./js/elementLocation");
wmf.transformer = require("./js/transformer");
wmf.utilities = require("./js/utilities");
wmf.findInPage = require("./js/findInPage");

window.wmf = wmf;
},{"./js/elementLocation":2,"./js/findInPage":3,"./js/transformer":6,"./js/utilities":13}],2:[function(require,module,exports){
//  Created by Monte Hurd on 12/28/13.
//  Used by methods in "UIWebView+ElementLocation.h" category.
//  Copyright (c) 2013 Wikimedia Foundation. Provided under MIT-style license; please copy and modify!

function stringEndsWith(str, suffix) {
    return str.indexOf(suffix, str.length - suffix.length) !== -1;
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
    // Important: use "X", "Y", "Width" and "Height" keys so we can use CGRectMakeWithDictionaryRepresentation in native land to convert to CGRect.
    return {
        Y: rect.top,
        X: rect.left,
        Width: rect.width,
        Height: rect.height
    };
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
// Based on the excellent blog post:
// http://www.icab.de/blog/2010/01/12/search-and-highlight-text-in-uiwebview/

var FindInPageResultCount = 0;
var FindInPageResultMatches = [];
var FindInPagePreviousFocusMatchSpanId = null;

function recursivelyHighlightSearchTermInTextNodesStartingWithElement(element, searchTerm) {
    if (element) {
        if (element.nodeType == 3) {            // Text node
            while (true) {
                var value = element.nodeValue;  // Search for searchTerm in text node
                var idx = value.toLowerCase().indexOf(searchTerm);
                
                if (idx < 0) break;
                
                var span = document.createElement("span");
                var text = document.createTextNode(value.substr(idx, searchTerm.length));
                span.appendChild(text);
                span.setAttribute("class", "findInPageMatch");

                text = document.createTextNode(value.substr(idx + searchTerm.length));
                element.deleteData(idx, value.length - idx);
                var next = element.nextSibling;
                element.parentNode.insertBefore(span, next);
                element.parentNode.insertBefore(text, next);
                element = text;
                FindInPageResultCount++;
            }
        } else if (element.nodeType == 1) {     // Element node
            if (element.style.display != "none" && element.nodeName.toLowerCase() != "select") {
                for (var i = element.childNodes.length - 1; i >= 0; i--) {
                    recursivelyHighlightSearchTermInTextNodesStartingWithElement(element.childNodes[i], searchTerm);
                }
            }
        }
    }
}

function recursivelyRemoveSearchTermHighlightsStartingWithElement(element) {
    if (element) {
        if (element.nodeType == 1) {
            if (element.getAttribute("class") == "findInPageMatch") {
                var text = element.removeChild(element.firstChild);
                element.parentNode.insertBefore(text,element);
                element.parentNode.removeChild(element);
                return true;
            } else {
                var normalize = false;
                for (var i = element.childNodes.length - 1; i >= 0; i--) {
                    if (recursivelyRemoveSearchTermHighlightsStartingWithElement(element.childNodes[i])) {
                        normalize = true;
                    }
                }
                if (normalize) {
                    element.normalize();
                }
            }
        }
    }
    return false;
}

function deFocusPreviouslyFocusedSpan() {
    if(FindInPagePreviousFocusMatchSpanId){
        document.getElementById(FindInPagePreviousFocusMatchSpanId).classList.remove("findInPageMatch_Focus");
        FindInPagePreviousFocusMatchSpanId = null;
    }
}

function removeSearchTermHighlights() {
    FindInPageResultCount = 0;
    FindInPageResultMatches = [];
    deFocusPreviouslyFocusedSpan();
    recursivelyRemoveSearchTermHighlightsStartingWithElement(document.body);
}

function findAndHighlightAllMatchesForSearchTerm(searchTerm) {
    removeSearchTermHighlights();
    if (searchTerm.trim().length === 0){
        window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches);
        return;
    }
    searchTerm = searchTerm.trim();
    
    recursivelyHighlightSearchTermInTextNodesStartingWithElement(document.body, searchTerm.toLowerCase());
    
    // The recursion doesn't walk a first-to-last path, so it doesn't encounter the
    // matches in first-to-last order. We can work around this by adding the "id"
    // and building our results array *after* the recursion is done, thanks to
    // "getElementsByClassName".
    var orderedMatchElements = document.getElementsByClassName("findInPageMatch");
    FindInPageResultMatches.length = orderedMatchElements.length;
    for (var i = 0; i < orderedMatchElements.length; i++) {
        var matchSpanId = "findInPageMatchID|" + i;
        orderedMatchElements[i].setAttribute("id", matchSpanId);
        // For now our results message to native land will be just an array of match span ids.
        FindInPageResultMatches[i] = matchSpanId;
    }
    
    window.webkit.messageHandlers.findInPageMatchesFound.postMessage(FindInPageResultMatches);
}

function useFocusStyleForHighlightedSearchTermWithId(id) {
    deFocusPreviouslyFocusedSpan();
    setTimeout(function(){
        document.getElementById(id).classList.add("findInPageMatch_Focus");
        FindInPagePreviousFocusMatchSpanId = id;
    }, 0);
}

exports.findAndHighlightAllMatchesForSearchTerm = findAndHighlightAllMatchesForSearchTerm;
exports.useFocusStyleForHighlightedSearchTermWithId = useFocusStyleForHighlightedSearchTermWithId;
exports.removeSearchTermHighlights = removeSearchTermHighlights;

},{}],4:[function(require,module,exports){
(function () {
var refs = require("./refs");
var utilities = require("./utilities");
var tableCollapser = require("./transforms/collapseTables");

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

/**
 * Attempts to send message which corresponds to `hrefTarget`, based on various attributes.
 * @return `true` if a message was sent, otherwise `false`.
 */
function maybeSendMessageForTarget(event, hrefTarget){
    if (!hrefTarget) {
        return false;
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
    var didDetectHangingTouchend = (event.touches.length > 0);
    if(didDetectHangingTouchend){
        return false;
    }
 
    var href = hrefTarget.getAttribute( "href" );
    var hrefClass = hrefTarget.getAttribute('class');
    if (hrefTarget.getAttribute( "data-action" ) === "edit_section") {
        window.webkit.messageHandlers.editClicked.postMessage({ sectionId: hrefTarget.getAttribute( "data-id" ) });
    } else if (href && refs.isCitation(href)) {
        // Handle reference links with a popup view instead of scrolling about!
        refs.sendNearbyReferences( hrefTarget );
    } else if (href && href[0] === "#") {
 
        tableCollapser.openCollapsedTableIfItContainsElement(document.getElementById(href.substring(1)));
 
        // If it is a link to an anchor in the current page, use existing link handling
        // so top floating native header height can be taken into account by the regular
        // fragment handling logic.
        window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href });
    } else if (typeof hrefClass === 'string' && hrefClass.indexOf('image') !== -1) {
         window.webkit.messageHandlers.imageClicked.postMessage({
                                                          'src': event.target.getAttribute('src'),
                                                          'width': event.target.naturalWidth,   // Image should be fetched by time it is tapped, so naturalWidth and height should be available.
                                                          'height': event.target.naturalHeight,
 														  'data-file-width': event.target.getAttribute('data-file-width'),
 														  'data-file-height': event.target.getAttribute('data-file-height')
                                                          });
    } else if (href) {
        window.webkit.messageHandlers.linkClicked.postMessage({ 'href': href });
    } else {
        return false;
    }
    return true;
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
        window.webkit.messageHandlers.nonAnchorTouchEndedWithoutDragging.postMessage({
                                                  id: event.target.getAttribute( "id" ),
                                                  tagName: event.target.tagName
                                                  });

    }
}

function handleTouchEnded(event){
    var touchobj = event.changedTouches[0];
    var touchEndY = parseInt(touchobj.clientY);
    if (((touchDownY - touchEndY) === 0) && (event.changedTouches.length === 1)) {
        // None of our tap events should fire if the user dragged vertically.
        touchEndedWithoutDragging(event);
    }
}

document.addEventListener("touchend", handleTouchEnded, false);

})();

},{"./refs":5,"./transforms/collapseTables":8,"./utilities":13}],5:[function(require,module,exports){
var elementLocation = require("./elementLocation");

function isCitation( href ) {
    return href.indexOf("#cite_note") > -1;
}

function isEndnote( href ) {
    return href.indexOf("#endnote_") > -1;
}

function isReference( href ) {
    return href.indexOf("#ref_") > -1;
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

function hasCitationLink( element ) {
    try {
        return isCitation( goDown( element ).getAttribute( "href" ) );
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
    var selectedIndex = 0;
    var refs = [];
    var linkId = [];
    var linkText = [];
    var linkRects = [];
    var curNode = sourceNode;

    // handle clicked ref:
    refs.push( collectRefText( curNode ) );
    linkId.push( collectRefLink( curNode ) );
    linkText.push( curNode.textContent );

    // go left:
    curNode = sourceNode.parentElement;
    while ( hasCitationLink( goLeft( curNode ) ) ) {
        selectedIndex += 1;
        curNode = goLeft( curNode );
        refs.unshift( collectRefText( goDown ( curNode ) ) );
        linkId.unshift( collectRefLink( curNode ) );
        linkText.unshift( curNode.textContent );
    }

    // go right:
    curNode = sourceNode.parentElement;
    while ( hasCitationLink( goRight( curNode ) ) ) {
        curNode = goRight( curNode );
        refs.push( collectRefText( goDown ( curNode ) ) );
        linkId.push( collectRefLink( curNode ) );
        linkText.push( curNode.textContent );
    }

    for(var i = 0; i < linkId.length; i++){
        var rect = elementLocation.getElementRect(document.getElementById(linkId[i]));
        linkRects.push(rect);
    }
    
    var referencesGroup = [];
    for(var j = 0; j < linkId.length; j++){
        referencesGroup.push({
                             "id": linkId[j],
                             "rect": linkRects[j],
                             "text": linkText[j],
                             "html": refs[j]
        });
    }
    
    // Special handling for references
    window.webkit.messageHandlers.referenceClicked.postMessage({
                                                               "selectedIndex": selectedIndex,
                                                               "referencesGroup": referencesGroup
                                                               });
}

exports.isEndnote = isEndnote;
exports.isReference = isReference;
exports.isCitation = isCitation;
exports.sendNearbyReferences = sendNearbyReferences;

},{"./elementLocation":2}],6:[function(require,module,exports){
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

},{}],7:[function(require,module,exports){

const transformer = require('../transformer');

class WMFPage {
    constructor(title, thumbnail, terms, extract) {
        this.title = title;
        this.thumbnail = thumbnail;
        this.terms = terms;
        this.extract = extract;
    }
}

class WMFPageFragment {
    constructor(wmfPage, index) {
        var pageContainer = document.createElement('div');
        pageContainer.id = index;
        pageContainer.className = 'footer_readmore_page';

        var containerAnchor = document.createElement('a');
        containerAnchor.href = '/wiki/' + wmfPage.title.replace(/ /g, '_');
        pageContainer.appendChild(containerAnchor);

        var bottomActions = document.createElement('div');
        bottomActions.id = index;
        bottomActions.className = 'footer_readmore_page_actions';
        pageContainer.appendChild(bottomActions);

        if(wmfPage.title){
            var title = document.createElement('h3');
            title.id = index;
            title.className = 'footer_readmore_page_title';
            title.innerHTML = wmfPage.title;
            containerAnchor.appendChild(title);
        }

        if(wmfPage.thumbnail){
            var img = document.createElement('img');
            img.id = index;
            img.className = 'footer_readmore_page_thumbnail';
            img.src = wmfPage.thumbnail.source;
            img.width = 120;
            containerAnchor.appendChild(img);
        }

        if(wmfPage.terms){
            var description = document.createElement('h4');
            description.id = index;
            description.className = 'footer_readmore_page_description';
            description.innerHTML = wmfPage.terms.description;
            containerAnchor.appendChild(description);
        }

        if(wmfPage.extract){
            var extract = document.createElement('div');
            extract.id = index;
            extract.className = 'footer_readmore_page_extract';
            extract.innerHTML = wmfPage.extract;
            containerAnchor.appendChild(extract);
        }

        var saveAnchor = document.createElement('a');
        saveAnchor.id = index;
        saveAnchor.innerText = 'Save for later';
        saveAnchor.className = 'footer_readmore_page_action_save';
        saveAnchor.href = '/wiki/Dog';
        bottomActions.appendChild(saveAnchor);
        
        return document.createDocumentFragment().appendChild(pageContainer);
    }
}

const showReadMore = (pages) => {
  const app_footer_readmore = document.getElementById('app_footer_readmore');
  pages.forEach((page, index) => {
    const pageModel = new WMFPage(page.title, page.thumbnail, page.terms, page.extract);
    const pageFragment = new WMFPageFragment(pageModel, index);
    app_footer_readmore.appendChild(pageFragment);
  });
};

// Leave 'baseURL' null if you don't need to deal with proxying.
const fetchReadMore = (baseURL, title, showReadMoreHandler) => {
    var xhr = new XMLHttpRequest();
    if (baseURL === null) {
      baseURL = '';
    }
    
    const pageCountToFetch = 3;
    const params = {
      action: 'query',
      continue: '',
      exchars: 256,
      exintro: 1,
      exlimit: pageCountToFetch,
      explaintext: '',
      format: 'json',
      generator: 'search',
      gsrinfo: '',
      gsrlimit: pageCountToFetch,
      gsrnamespace: 0,
      gsroffset: 0,
      gsrprop: 'redirecttitle',
      gsrsearch: `morelike:${title}`,
      gsrwhat: 'text',
      ns: 'ppprop',
      pilimit: pageCountToFetch,
      piprop: 'thumbnail',
      pithumbsize: 320,
      prop: 'pageterms|pageimages|pageprops|revisions|extracts',
      rrvlimit: 1,
      rvprop: 'ids',
      wbptterms: 'description',
      formatversion: 2
    };

    const paramsString = Object.keys(params)
      .map(key => `${encodeURIComponent(key)}=${encodeURIComponent(params[key])}`).join('&');
    
    xhr.open('GET', `${baseURL}/w/api.php?${paramsString}`, true);
    xhr.onload = () => {
      if (xhr.readyState === 4) {
        if (xhr.status === 200) {
            showReadMoreHandler(JSON.parse(xhr.responseText).query.pages);
        } else {
          // console.error(xhr.statusText);
        }
      }
    };
    xhr.onerror = (e) => {
      console.log(`${e}`);
      // console.error(xhr.statusText);
    };
    xhr.send(null);
};

transformer.register('addReadMoreFooter', function(baseURL, title) {
  fetchReadMore(baseURL, title, showReadMore);
});

},{"../transformer":6}],8:[function(require,module,exports){
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

exports.openCollapsedTableIfItContainsElement = function(element){
    if(element){
        var container = utilities.findClosest(element, "[class*='app_table_container']");
        if(container){
            var collapsedDiv = container.firstChild;
            if(collapsedDiv && collapsedDiv.classList.contains('app_table_collapsed_open')){
                collapsedDiv.click();
            }
        }
    }
};

},{"../transformer":6,"../utilities":13}],9:[function(require,module,exports){
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

},{"../transformer":6}],10:[function(require,module,exports){
var transformer = require("../transformer");

transformer.register( "hideRedlinks", function( content ) {
	var redLinks = content.querySelectorAll( 'a.new' );
	for ( var i = 0; i < redLinks.length; i++ ) {
		var redLink = redLinks[i];
        redLink.style.color = 'inherit';
	}
} );

},{"../transformer":6}],11:[function(require,module,exports){
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

},{"../transformer":6}],12:[function(require,module,exports){

const transformer = require('../transformer');
const maybeWidenImage = require('applib').WidenImage.maybeWidenImage;

const isGalleryImage = function(image) {
  // 'data-image-gallery' is added to 'gallery worthy' img tags before html is sent to WKWebView.
  // WidenImage's maybeWidenImage code will do further checks before it widens an image.
  return (image.getAttribute('data-image-gallery') === 'true');    
};

transformer.register('widenImages', function(content) {
  Array.from(content.querySelectorAll('img'))
    .filter(isGalleryImage)
    .forEach(maybeWidenImage);
});

},{"../transformer":6,"applib":14}],13:[function(require,module,exports){

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

},{}],14:[function(require,module,exports){
'use strict';

/**
  Tries to get an array of table header (TH) contents from a given table. If
  there are no TH elements in the table, an empty array is returned.
  @param {!Element} element Table or blob of HTML containing a table?
  @param {?string} pageTitle
  @return {!Array<string>}
*/
var getTableHeader = function getTableHeader(element, pageTitle) {
  var thArray = [];

  if (element.children === undefined || element.children === null) {
    return thArray;
  }

  for (var i = 0; i < element.children.length; i++) {
    var el = element.children[i];

    if (el.tagName === 'TH') {
      // ok, we have a TH element!
      // However, if it contains more than two links, then ignore it, because
      // it will probably appear weird when rendered as plain text.
      var aNodes = el.querySelectorAll('a');
      if (aNodes.length < 3) {
        // todo: remove nonstandard Element.innerText usage
        // Also ignore it if it's identical to the page title.
        if ((el.innerText && el.innerText.length || el.textContent.length) > 0 && el.innerText !== pageTitle && el.textContent !== pageTitle && el.innerHTML !== pageTitle) {
          thArray.push(el.innerText || el.textContent);
        }
      }
    }

    // if it's a table within a table, don't worry about it
    if (el.tagName === 'TABLE') {
      continue;
    }

    // recurse into children of this element
    var ret = getTableHeader(el, pageTitle);

    // did we get a list of TH from this child?
    if (ret.length > 0) {
      thArray = thArray.concat(ret);
    }
  }

  return thArray;
};

var CollapseTable = {
  getTableHeader: getTableHeader
};

/**
 * Returns closest ancestor of element which matches selector.
 * Similar to 'closest' methods as seen here:
 *  https://api.jquery.com/closest/
 *  https://developer.mozilla.org/en-US/docs/Web/API/Element/closest
 * @param  {!Element} el        Element
 * @param  {!string} selector   Selector to look for in ancestors of 'el'
 * @return {?HTMLElement}       Closest ancestor of 'el' matching 'selector'
 */
var findClosest = function findClosest(el, selector) {
  while ((el = el.parentElement) && !el.matches(selector)) {
    // Intentionally empty.
    // Reminder: the parenthesis around 'el = el.parentElement' are also intentional.
  }
  return el;
};

/**
 * Determines if element has a table ancestor.
 * @param  {!Element}  el   Element
 * @return {boolean}        Whether table ancestor of 'el' is found
 */
var isNestedInTable = function isNestedInTable(el) {
  return findClosest(el, 'table') !== null;
};

var elementUtilities = {
  findClosest: findClosest,
  isNestedInTable: isNestedInTable
};

/**
 * To widen an image element a css class called 'wideImageOverride' is applied to the image element,
 * however, ancestors of the image element can prevent the widening from taking effect. This method
 * makes minimal adjustments to ancestors of the image element being widened so the image widening
 * can take effect.
 * @param  {!HTMLElement} el Element whose ancestors will be widened
 */
var widenAncestors = function widenAncestors(el) {
  while ((el = el.parentElement) && !el.classList.contains('content_block')) {
    // Reminder: the parenthesis around 'el = el.parentElement' are intentional.
    if (el.style.width) {
      el.style.width = '100%';
    }
    if (el.style.maxWidth) {
      el.style.maxWidth = '100%';
    }
    if (el.style.float) {
      el.style.float = 'none';
    }
  }
};

/**
 * Some images should not be widended. This method makes that determination.
 * @param  {!HTMLElement} image   The image in question
 * @return {boolean}              Whether 'image' should be widened
 */
var shouldWidenImage = function shouldWidenImage(image) {
  // Images within a "<div class='noresize'>...</div>" should not be widened.
  // Example exhibiting links overlaying such an image:
  //   'enwiki > Counties of England > Scope and structure > Local government'
  if (elementUtilities.findClosest(image, "[class*='noresize']")) {
    return false;
  }

  // Side-by-side images should not be widened. Often their captions mention 'left' and 'right', so
  // we don't want to widen these as doing so would stack them vertically.
  // Examples exhibiting side-by-side images:
  //    'enwiki > Cold Comfort (Inside No. 9) > Casting'
  //    'enwiki > Vincent van Gogh > Letters'
  if (elementUtilities.findClosest(image, "div[class*='tsingle']")) {
    return false;
  }

  // Imagemaps, which expect images to be specific sizes, should not be widened.
  // Examples can be found on 'enwiki > Kingdom (biology)':
  //    - first non lead image is an image map
  //    - 'Three domains of life > Phylogenetic Tree of Life' image is an image map
  if (image.hasAttribute('usemap')) {
    return false;
  }

  // Images in tables should not be widened - doing so can horribly mess up table layout.
  if (elementUtilities.isNestedInTable(image)) {
    return false;
  }

  return true;
};

/**
 * Removes barriers to images widening taking effect.
 * @param  {!HTMLElement} image   The image in question
 */
var makeRoomForImageWidening = function makeRoomForImageWidening(image) {
  widenAncestors(image);

  // Remove width and height attributes so wideImageOverride width percentages can take effect.
  image.removeAttribute('width');
  image.removeAttribute('height');
};

/**
 * Widens the image.
 * @param  {!HTMLElement} image   The image in question
 */
var widenImage = function widenImage(image) {
  makeRoomForImageWidening(image);
  image.classList.add('wideImageOverride');
};

/**
 * Widens an image if the image is found to be fit for widening.
 * @param  {!HTMLElement} image   The image in question
 * @return {boolean}              Whether or not 'image' was widened
 */
var maybeWidenImage = function maybeWidenImage(image) {
  if (shouldWidenImage(image)) {
    widenImage(image);
    return true;
  }
  return false;
};

var WidenImage = {
  maybeWidenImage: maybeWidenImage,
  test: {
    shouldWidenImage: shouldWidenImage,
    widenAncestors: widenAncestors
  }
};

var index = {
  CollapseTable: CollapseTable,
  WidenImage: WidenImage,
  test: {
    ElementUtilities: elementUtilities
  }
};

module.exports = index;


},{}]},{},[1,2,3,4,5,6,7,8,9,10,11,12,13]);
