var transformer = require("../transformer");

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

        // Move the P! Place it just after the lead section edit button.
        block_0.insertBefore(p, block_0.firstChild);

        // But only move one P!
        break;
    }
});
