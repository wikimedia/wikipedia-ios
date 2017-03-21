var transformer = require("../transformer");
var utilities = require("../utilities");

// If enabled, widened images will have thin red dashed border
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
    // 'data-image-gallery' is added to "gallery worthy" img tags before html is sent
    // to the web view. It is only added if an img is determined to be a good gallery img.
    // We can just check for this instead of trying to make gallery-worthiness
    // determinations again here in JS land.
    if(image.getAttribute('data-image-gallery') != "true"){
        return false;
    }
    
    // Some images are within a <div class="noresize">...</div> which indicates
    // they should not be widened. Example below has links overlaying such an image.
    // See:
    //      "enwiki > Counties of England > Scope and structure > Local government"
    if(utilities.findClosest(image, "[class*='noresize']")){
        return false;
    }
    
    // Imagemap coordinates are specific to a specific image size, so we never want to widen
    // these or the overlaying links will not be over the intended parts of the image.
    // See:
    //      "enwiki > Kingdom (biology) > first non lead image is an image map"
    //      "enwiki > Kingdom (biology) > Three domains of life > Phylogenetic Tree of Life image is an image map"
    if(image.hasAttribute("usemap")){
        return false;
    }

    // Don't widen if the image is nested in a table or the table layout can be messed up.
    if(utilities.isNestedInTable(image)){
        return false;
    }

    return true;
}

function makeRoomForImageWidening(image) {
    // Expand containment so css wideImageOverride width percentages can take effect.
    widenAncestors (image);

    // Remove width and height attributes so wideImageOverride width percentages can take effect.
    image.removeAttribute("width");
    image.removeAttribute("height");
}

function widenImage(image) {
    makeRoomForImageWidening (image);
    image.classList.add("wideImageOverride");

    if(enableDebugBorders){
        image.style.borderStyle = 'dashed';
        image.style.borderWidth = '1px';
        image.style.borderColor = '#f00';
    }
}

function maybeWidenImage(image) {
    if (shouldWidenImage(image)) {
        widenImage(image);
    }
}

transformer.register( "widenImages", function( content ) {
    var images = content.querySelectorAll( 'img' );
    for ( var i = 0; i < images.length; i++ ) {
        maybeWidenImage(images[i]);
    }
} );
