var transformer = require("./transformer");

// Move infobox to the bottom of the lead section
transformer.register( "leadSection", function( leadContent ) {
    var infobox = leadContent.querySelector( "table.infobox" );
    if ( infobox ) {
        infobox.parentNode.removeChild( infobox );
        var pTags = leadContent.getElementsByTagName( "p" );
        if ( pTags.length ) {
            pTags[0].appendChild( infobox );
        } else {
            leadContent.appendChild( infobox );
        }
    }
    return leadContent;
} );

transformer.register( "section", function( content ) {
	return content;
} );

transformer.register( "section", function( content ) {
	var redLinks = content.querySelectorAll( 'a.new' );
	for ( var i = 0; i < redLinks.length; i++ ) {
		var redLink = redLinks[i];
		var replacementSpan = document.createElement( 'span' );
		replacementSpan.innerHTML = redLink.innerHTML;
		replacementSpan.setAttribute( 'class', redLink.getAttribute( 'class' ) );
		redLink.parentNode.replaceChild( replacementSpan, redLink );
	}
	return content;
} );
