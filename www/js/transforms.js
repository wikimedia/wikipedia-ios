var transformer = require("./transformer");

transformer.register( "moveFirstGoodParagraphUp", function( content ) {
    /*
    Instead of moving the infobox down beneath the first P tag,
    move the first good looking P tag *up* (as the first child of
    the first section div). That way the first P text will appear not
    only above infoboxes, but above other tables/images etc too!
    */

    if(content.getElementById( "mainpage" ))return;

    var block_0 = content.getElementById( "content_block_0" );
    if(!block_0) return;

    var allPs = block_0.getElementsByTagName( "p" );
    if(!allPs) return;

    for ( var i = 0; i < allPs.length; i++ ) {
        var p = allPs[i];

        // Narrow down to first P which is direct child of content_block_0 DIV.
        // (Don't want to yank P from somewhere in the middle of a table!)
        if  (p.parentNode != block_0) continue;


        // Ensure the P being pulled up has at least a couple lines of text.
        // Otherwise silly things like a empty P or P which only contains a
        // BR tag will get pulled up (see articles on "Chemical Reaction" and
        // "Hawaii").
        // Trick for quickly determining element height:
        //      https://developer.mozilla.org/en-US/docs/Web/API/HTMLElement.offsetHeight
        //      http://stackoverflow.com/a/1343350/135557
        var minHeight = 40;
        var pIsTooSmall = (p.offsetHeight < minHeight);
        if(pIsTooSmall) continue;


        /*
        // Note: this works - just not sure if needed?
        // Sometimes P will be mostly image and not much text. Don't
        // want to move these!
        var pIsMostlyImage = false;
        var imgs = p.getElementsByTagName('img');
        for (var j = 0; j < imgs.length; j++) {
            var thisImg = imgs[j];
            // Get image height from img tag's height attribute - otherwise
            // you'd have to wait for the image to render (if you used offsetHeight).
            var thisImgHeight = thisImg.getAttribute("height");
            if(thisImgHeight == 0) continue;
            var imgHeightPercentOfParagraphTagHeight = thisImgHeight / p.offsetHeight;
            if (imgHeightPercentOfParagraphTagHeight > 0.5){
                pIsMostlyImage = true;
                break;
            }
        }
        if(pIsMostlyImage) continue;
        */


        // Move the P!
        block_0.insertBefore(p.parentNode.removeChild(p), block_0.firstChild);
        
        // But only move one P!
        break;
    }
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

