
function hideRedlinks( content ) {
	var redLinks = content.querySelectorAll( 'a.new' );
	for ( var i = 0; i < redLinks.length; i++ ) {
		var redLink = redLinks[i];
        redLink.style.color = 'inherit';
	}
}

exports.hideRedlinks = hideRedlinks;
