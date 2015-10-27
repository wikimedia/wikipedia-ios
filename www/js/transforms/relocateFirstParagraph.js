var transformer = require("../transformer");

function findFirstGoodParagraphIn( nodes ) {
    var minHeight = 40;
    var firstGoodParagraphIndex;
    var i;
    
    for (i = 0; i < nodes.length; i++) {
        if (nodes[i].tagName === 'P') {
            // Ensure the P being pulled up has at least a couple lines of text.
            // Otherwise silly things like a empty P or P which only contains a
            // BR tag will get pulled up (see articles on "Chemical Reaction" and
            // "Hawaii").
            // Trick for quickly determining element height:
            // https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement.offsetHeight
            // http://stackoverflow.com/a/1343350/135557
            var pIsTooSmall = (nodes[i].offsetHeight < minHeight);
            if (pIsTooSmall) continue;
            
            firstGoodParagraphIndex = i;
            break;
        }
    }
    
    return firstGoodParagraphIndex;
}

function addNode( span, node ) {
    span.appendChild( node.parentNode.removeChild( node ) );
}

function addTrailingNodes( span, nodes, startIndex ) {
    for ( var i = startIndex; i < nodes.length; i++ ) {
        if ( nodes[i].tagName === 'P' ) {
            break;
        }
        addNode( span, nodes[i] );
    }
}

// Create a lead span to be moved to the top of the page, consisting of the first
// qualifying <p> element encountered and any subsequent non-<p> elements until
// the next <p> is encountered.
//
// Simply moving the first <p> element up may result in the infobox appearing
// between the first paragraph as designated by <p></p> tags and other elements
// (such as an unnumbered list) that may also be intended as part of the first
// display paragraph.  See T111958.
function createLeadSpan( childNodes ) {
    var leadSpan = document.createElement( "span" );
    var firstGoodParagraphIndex = findFirstGoodParagraphIn( childNodes );
    
    if (firstGoodParagraphIndex) {
        addNode( leadSpan, childNodes[firstGoodParagraphIndex] );
        addTrailingNodes( leadSpan, childNodes, firstGoodParagraphIndex + 1 );
    }
    
    return leadSpan;
}

transformer.register( "moveFirstGoodParagraphUp", function( content ) {
    /*
    Instead of moving the infobox down beneath the first paragraph,
    move the first good looking paragraph *up* (as the first child of
    the first section div). That way it will appear not only above infoboxes, 
    but above other tables/images etc too!
    */

    if(content.getElementById( "mainpage" ))return;

    var block_0 = content.getElementById( "content_block_0" );
    if(!block_0) return;

    var block_0_children = block_0.childNodes;
    if (!block_0_children) return;

    var edit_section_button_0 = content.getElementById( "edit_section_button_0" );
    if(!edit_section_button_0) return;
                     
    var leadSpan = createLeadSpan(block_0_children);
    block_0.insertBefore( leadSpan, edit_section_button_0.nextSibling );
} );








