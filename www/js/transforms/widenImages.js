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
        image.hasAttribute('srcset') &&
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

function getDictionaryFromSrcset(srcset) {
    /*
     Returns dictionary with density (without "x") as keys and urls as values.
     Parameter 'srcset' string:
     '//image1.jpg 1.5x, //image2.jpg 2x, //image3.jpg 3x'
     Returns dictionary:
     {1.5: '//image1.jpg', 2: '//image2.jpg', 3: '//image3.jpg'}
     */
    var sets = srcset.split(',').map(function(set) {
                                     return set.trim().split(' ');
                                     });
    var output = {};
    sets.forEach(function(set) {
                 output[set[1].replace('x', '')] = set[0];
                 });
    return output;
}

function useHigherResolutionImageSrcFromSrcsetIfNecessary(image) {
    if (image.getAttribute('srcset')){
        var stretchRatio = getStretchRatio(image);
        if (stretchRatio > maxStretchRatioAllowedBeforeRequestingHigherResolution) {
            var srcsetDict = getDictionaryFromSrcset(image.getAttribute('srcset'));
            /*
            Grab the highest res url from srcset - avoids the complexity of parsing urls
            to retrieve variants - which can get tricky - canonicals have different paths 
            than size variants
            */
            var largestSrcsetDictKey = Object.keys(srcsetDict).reduce(function(a, b) {
              return a > b ? a : b;
            });

            image.src = srcsetDict[largestSrcsetDictKey];

            if(enableDebugBorders){
                image.style.borderWidth = '10px';
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

    useHigherResolutionImageSrcFromSrcsetIfNecessary(image);
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
