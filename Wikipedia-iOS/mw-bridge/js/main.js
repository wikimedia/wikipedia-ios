
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

     window.onload = function() {
        bridge.sendMessage( "DOMLoaded", {} );
     };
     
     bridge.registerListener( "append", function( payload ) {
          // Append html without losing existing event handlers
          // From: http://stackoverflow.com/a/595825
          var content = document.getElementById("content");
          var newcontent = document.createElement('div');
          newcontent.innerHTML = payload.html;
          while (newcontent.firstChild) {
             newcontent.firstChild = transforms.transform( "lead", newcontent.firstChild );
             content.appendChild(newcontent.firstChild);
          }
     });

     bridge.registerListener( "prepend", function( payload ) {
          // Prepend html without losing existing event handlers
          var content = document.getElementById("content");
          var newcontent = document.createElement('div');
          newcontent.innerHTML = payload.html;
          content.insertBefore(newcontent, content.firstChild);
     });

     bridge.registerListener( "remove", function( payload ) {
         document.getElementById( "content" ).removeChild(document.getElementById(payload.element));
     });

     bridge.registerListener( "clear", function( payload ) {
         document.getElementById( "content" ).innerHTML = '';
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