( function() {
 
    var Transforms = function () {};

    // List of transformation functions by their target type
    var transformsByType = {
        'lead': [
            moveInfobox
        ]
    }

    function moveInfobox( leadContent ) {
        // Move infobox to the bottom of the lead section
        var infobox = leadContent.querySelector( "table.infobox" );
        if ( infobox ) {
            infobox.parentNode.removeChild( infobox );
            leadContent.appendChild( infobox );
        }
        return leadContent;
    }

    Transforms.prototype.transform = function( type, content ) {
        var transforms = transformsByType[ type ];
        if ( transforms.length ) {
            transforms.forEach( function ( transform ) {
                content = transform( content );
            } );
        }
        return content;
    };
    window.transforms = new Transforms();
}) ();