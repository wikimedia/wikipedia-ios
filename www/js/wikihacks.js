
// this doesn't seem to work on iOS?
exports.makeTablesNotBlockIfSafeToDoSo = function() {
    // Tables which are narrower than their container look funny - this is caused by table
    // css 'display' being set to 'block'. But this *is needed* when the table content is
    // wider than the table's container. So conditionally set table display to 'table' if
    // the table isn't as wide as its container. Result: things which need horizontal
    // overflow scrolling still can do so, but things which don't need to scroll look
    // so much better. (See the "San Francisco" article with and without this method for
    // comparison.)
    var tbodies = document.getElementsByTagName('TBODY');
    for (var i = 0; i < tbodies.length; ++i) {
        var tbody = tbodies[i];
        var tbodyRect = tbody.getBoundingClientRect();
        var parentRect = tbody.parentElement.getBoundingClientRect();
        //var style = window.getComputedStyle(tbody);
        if(tbodyRect.width < parentRect.width){
            tbody.parentElement.style.float = "";
            tbody.parentElement.style.margin = "";
            tbody.parentElement.style.display = 'table';
        }
    }
}

// this *does* seem to work on ios
// wrap wide tables in a <div style="overflow-x:auto">...</div>
exports.putWideTablesInDivs = function() {
    var tbodies = document.getElementsByTagName('TBODY');
    for (var i = 0; i < tbodies.length; ++i) {
        var tbody = tbodies[i];
        var tbodyRect = tbody.getBoundingClientRect();
        var parentRect = tbody.parentElement.getBoundingClientRect(); // this doesn't give a useful result, as parent is sized to the table?
        //if(tbodyRect.width >= parentRect.width){
            var table = tbody.parentElement;
            var parent = table.parentElement;
            var div = document.createElement( 'div' );
            div.style.overflowX = 'auto';
            parent.insertBefore( div, table );
            var oldTable = parent.removeChild( table );
            div.appendChild( oldTable );
        //}
    }
}


exports.reduceWeirdWebkitMargin = function() {
    // See the "Tuna" article for tables having weird left margin. This removes it.
    var dds = document.getElementsByTagName('DD');
    for (var i = 0; i < dds.length; ++i) {
        dds[i].style["-webkit-margin-start"] = "1px";
    }
}

exports.allowDivWidthsToFlow = function() {
    // See the "San Francisco" article for divs having weird margin issues. This fixes.
    var divs = document.getElementsByTagName('div');
    for (var i = 0; i < divs.length; ++i) {
        divs[i].style.width = "";
    }
}

exports.hideAudioTags = function() {
    // The audio tag can't be completely hidden in css for some reason - need to clear its
    // "controls" attribute for it to not display a "could not play audio" grey box.
    var audio = document.getElementsByTagName('AUDIO');
    for (var i = 0; i < audio.length; ++i) {
        var thisAudio = audio[i];
        thisAudio.controls = '';
        thisAudio.style.display = 'none';
    }
}

exports.tweakFilePage = function() {
    var filetoc = document.getElementById( 'filetoc' );
    if (filetoc) {
        // We're on a File: page! Do some quick hacks.
        // In future, replace entire thing with a custom view most of the time.
        var content = document.getElementById( 'content' );
        
        // Hide edit sections
        var editSections = content.querySelectorAll('.edit_section_button');
        for (var i = 0; i < editSections.length; i++) {
            editSections[i].style.display = 'none';
        }
        
        var fullImageLink = content.querySelector('.fullImageLink a');
        if (fullImageLink) {
            // Don't replace the a with a span, as it will break styles
            // Just disable clicking.
            // Don't disable touchstart as this breaks scrolling!
            fullImageLink.href = '';
            fullImageLink.addEventListener( 'click', function( event ) {
                event.preventDefault();
            } );
        }
    }
}
