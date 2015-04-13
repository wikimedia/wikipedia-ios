var transformer = require("../transformer");

function firstAncestorWithMultipleChildren (el) {
    while ((el = el.parentElement) && (el.childElementCount == 1));
    return el;
}

function addImageOverflowXContainer() {
    var image = this;
    if (image.width > (window.screen.width * 0.8)){
        var ancestor = firstAncestorWithMultipleChildren (image);
        if(ancestor){
            var div = document.createElement( 'div' );
            div.className = 'image_overflow_x_container';
            ancestor.parentElement.insertBefore( div, ancestor );
            div.appendChild( ancestor );
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
        images[i].addEventListener('load', addImageOverflowXContainer, false);
    }
} );
