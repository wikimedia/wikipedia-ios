var bridge = require("./bridge");
var wikihacks = require("./wikihacks");
var transformer = require("./transformer");
var refs = require("./refs");

//TODO: move makeTablesNotBlockIfSafeToDoSo, hideAudioTags and reduceWeirdWebkitMargin out into own js object.

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

bridge.registerListener( "append", function( payload ) {
    // Append html without losing existing event handlers
    // From: http://stackoverflow.com/a/595825
    var content = document.getElementById("content");
    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;
                        
    var isFirstSection = true;
    while (newcontent.firstChild) {
        var section = newcontent.removeChild(newcontent.firstChild);
        if (section.nodeType == Node.ELEMENT_NODE) {
            if (isFirstSection) {
                section = transformer.transform( "leadSection", section );
                isFirstSection = false;
            }
            section = transformer.transform( "section", section );
        }
        content.appendChild(section);
    }

    // Things which need to happen any time data is appended.
    //TODO: later could optimize to only perform actions on elements found
    // within the content div which was appended).

    // TODO: migrate these into common transforms?

    wikihacks.putWideTablesInDivs();
/*
    wikihacks.makeTablesNotBlockIfSafeToDoSo();
    wikihacks.reduceWeirdWebkitMargin();
 */
    wikihacks.hideAudioTags();
/*
    wikihacks.allowDivWidthsToFlow();
*/
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
/*
        if ( refs.isReference( href ) ) {
            // Handle reference links with a popup view instead of scrolling about!
            refs.sendNearbyReferences( anchorTarget );
        } else
*/
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
                // Do NOT prevent default behavior -- this is needed to for instance
                // handle deselection of text.
                bridge.sendMessage( 'nonAnchorTouchEndedWithoutDragging', { id: event.target.getAttribute( "id" ), tagName: event.target.tagName});
            }
        }
    }
}

document.addEventListener("touchend", touchEnd, "false");
