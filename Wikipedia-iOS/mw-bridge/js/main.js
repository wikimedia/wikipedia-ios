
( function() {

     function forEach( list, fun ) {
        // Hack from https://developer.mozilla.org/en-US/docs/Web/API/NodeList#Workarounds
        // To let me use forEach on things like NodeList objects
        Array.prototype.forEach.call( list, fun );
     }

     var Bridge = function() {
        this.eventHandlers = {};
     };
     
     Bridge.prototype.handleMessage = function( type, payload ) {
     var that = this;
         if ( this.eventHandlers.hasOwnProperty( type ) ) {
             this.eventHandlers[type].forEach( function( callback ) {
                callback.call( that, payload );
             } );
         }
     };
     
     Bridge.prototype.registerListener = function( messageType, callback ) {
         if ( this.eventHandlers.hasOwnProperty( messageType ) ) {
            this.eventHandlers[messageType].push( callback );
         } else {
            this.eventHandlers[messageType] = [ callback ];
         }
     };
     
     Bridge.prototype.sendMessage = function( messageType, payload ) {
        var messagePack = { type: messageType, payload: payload };
        var url = "x-wikipedia-bridge:" + JSON.stringify( messagePack );
     
        // quick iframe version based on http://stackoverflow.com/a/6508343/82439
        // fixme can this be an XHR instead? check Cordova current state
        var iframe = document.createElement('iframe');
        iframe.setAttribute("src", url);
        document.documentElement.appendChild(iframe);
        iframe.parentNode.removeChild(iframe);
        iframe = null;
     };
     
     window.bridge = new Bridge();






//TODO: move makeTablesNotBlockIfSafeToDoSo, hideAudioTags and reduceWeirdWebkitMargin out into
// own js object for things which need to happen once the entire document is ready (as opposed
// to section-level transforms).

     function makeTablesNotBlockIfSafeToDoSo() {
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

     function reduceWeirdWebkitMargin() {
        // See the "Tuna" article for tables having weird left margin. This removes it.
        var dds = document.getElementsByTagName('DD');
        for (var i = 0; i < dds.length; ++i) {
            dds[i].style["-webkit-margin-start"] = "1px";
        }
     }

     function allowDivWidthsToFlow() {
        // See the "San Francisco" article for divs having weird margin issues. This fixes.
        var divs = document.getElementsByTagName('div');
        for (var i = 0; i < divs.length; ++i) {
            divs[i].style.width = "";
        }
     }

     function hideAudioTags() {
        // The audio tag can't be completely hidden in css for some reason - need to clear its
        // "controls" attribute for it to not display a "could not play audio" grey box.
        var audio = document.getElementsByTagName('AUDIO');
        for (var i = 0; i < audio.length; ++i) {
            var thisAudio = audio[i];
            thisAudio.controls = '';
            thisAudio.style.display = 'none';
        }
     }






     window.onload = function() {
        bridge.sendMessage( "DOMLoaded", {} );
 
        // Things which need to happen after entire page is ready.
        makeTablesNotBlockIfSafeToDoSo();
        reduceWeirdWebkitMargin();
        hideAudioTags();
        allowDivWidthsToFlow();

     };
     
     bridge.registerListener( "append", function( payload ) {
          // Append html without losing existing event handlers
          // From: http://stackoverflow.com/a/595825
          var content = document.getElementById("ios_app_content");
          var newcontent = document.createElement('div');
          newcontent.innerHTML = payload.html;
          while (newcontent.firstChild) {
// Quite often this pushes the first image pretty far offscreen... hmmm...
//             newcontent.firstChild = transforms.transform( "lead", newcontent.firstChild );
             content.appendChild(newcontent.firstChild);
          }
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
             event.preventDefault();
         }
     }
 
} )();
