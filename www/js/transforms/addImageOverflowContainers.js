var transformer = require("../transformer");
var utilities = require("../utilities");

function shouldAddImageOverflowXContainer(image) {
    return ((image.width > (window.screen.width * 0.8)) && !utilities.isNestedInTable(image)) ? true : false;
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

function maybeAddImageOverflowXContainer(image) {
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
        maybeAddImageOverflowXContainer(images[i]);
    }
} );
