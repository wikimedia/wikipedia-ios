var bridge = require("./bridge");
var wikihacks = require("./wikihacks");

//TODO: move makeTablesNotBlockIfSafeToDoSo, hideAudioTags and reduceWeirdWebkitMargin out into own js object.

bridge.registerListener( "setLanguage", function( payload ){
    var body = document.querySelector( "body" );
    body.lang = payload.lang;
    body.dir = payload.dir;
} );

bridge.registerListener( "setScale", function( payload ) {
    var contentSettings = [
        "width=device-width",
        "initial-scale=1.0",
        "user-scalable=yes",
        "minimum-scale=" + payload.min,
        "maximum-scale=" + payload.max
    ];
    var content = contentSettings.join(", ");
    document.getElementById("viewport").setAttribute('content', content);
} );

bridge.registerListener( "append", function( payload ) {
    // Append html without losing existing event handlers
    // From: http://stackoverflow.com/a/595825
    var content = document.getElementById("ios_app_content");
    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;

    while (newcontent.firstChild) {
// Quite often this pushes the first image pretty far offscreen... hmmm...
//      newcontent.firstChild = transforms.transform( "lead", newcontent.firstChild );
        content.appendChild(newcontent.firstChild);
    }
    // Things which need to happen any time data is appended.
    //TODO: later could optimize to only perform actions on elements found
    // within the ios_app_content div which was appended).
    wikihacks.makeTablesNotBlockIfSafeToDoSo();
    wikihacks.reduceWeirdWebkitMargin();
    wikihacks.hideAudioTags();
    wikihacks.allowDivWidthsToFlow();
});

bridge.registerListener( "prepend", function( payload ) {
    // Prepend html without losing existing event handlers
    var content = document.getElementById("ios_app_content");
    var newcontent = document.createElement('div');
    newcontent.innerHTML = payload.html;
    content.insertBefore(newcontent, content.firstChild);
});

bridge.registerListener( "remove", function( payload ) {
    document.getElementById( "ios_app_content" ).removeChild(document.getElementById(payload.element));
});

bridge.registerListener( "clear", function( payload ) {
    document.getElementById( "ios_app_content" ).innerHTML = '';
});

bridge.registerListener( "ping", function( payload ) {
    bridge.sendMessage( "pong", payload );
});

document.onclick = function() {
    if ( event.target.tagName === "A" ) {
        bridge.sendMessage( 'linkClicked', { href: event.target.getAttribute( "href" ) });
    }
    event.preventDefault();
}

touchDownY = 0.0;
function touchStart(event){
    touchDownY = parseInt(event.changedTouches[0].clientY);
}
document.addEventListener("touchstart", touchStart, "false");

function touchEnd(event){
    var touchobj = event.changedTouches[0];
    touchEndY = parseInt(touchobj.clientY);
    if ( event.target.tagName != "A" && ((touchDownY - touchEndY) == 0) && (event.changedTouches.length == 1)) {
        
        if ( event.target.className === "edit_section" ) {
            bridge.sendMessage( 'editClicked', { href: event.target.getAttribute( "id" ) });
        }else{
            bridge.sendMessage( 'nonAnchorTouchEndedWithoutDragging', { id: event.target.getAttribute( "id" ), tagName: event.target.tagName});
        }
    }
}

document.addEventListener("touchend", touchEnd, "false");
