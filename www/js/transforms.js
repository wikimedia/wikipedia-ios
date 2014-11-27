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

