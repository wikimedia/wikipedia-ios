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
        image.hasAttribute('data-file-width') &&
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

function useHigherResolutionImageSrcIfNecessary(image) {
    var src = image.getAttribute('src');
    if (src){
        var stretchRatio = getStretchRatio(image);
        if (stretchRatio > maxStretchRatioAllowedBeforeRequestingHigherResolution) {
			var pathComponents = src.split("/");
			var filename = pathComponents[pathComponents.length - 1];
			var sizeRegex = /^[0-9]+(?=px-)/;
			var sizeMatches = filename.match(sizeRegex);
			if (sizeMatches.length > 0) {
				var size = parseInt(sizeMatches[0]);
				var originalSize = parseInt(image.getAttribute('data-file-width'));
				var newSize = size*stretchRatio*window.devicePixelRatio;
				var newSrc = pathComponents.slice(0,-1).join('/');
				if (newSize < originalSize) {
					var newFilename = filename.replace(sizeRegex, newSize.toString());
					newSrc = newSrc + '/' + newFilename;
				} else {
					newSrc = newSrc.replace('/thumb/', '/');
				}
				image.src = newSrc;
	            if(enableDebugBorders){
	                image.style.borderWidth = '10px';
	            }
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

    useHigherResolutionImageSrcIfNecessary(image);
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
