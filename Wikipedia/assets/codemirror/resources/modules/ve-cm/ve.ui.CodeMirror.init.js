( function () {
	mw.libs.ve.targetLoader.addPlugin( function () {
		var index,
			target = ve.init.mw.DesktopArticleTarget;

		if ( target ) {
			index = target.static.actionGroups[ 1 ].include.indexOf( 'changeDirectionality' );
			target.static.actionGroups[ 1 ].include.splice( index, 0, 'codeMirror' );
		}
	} );
}() );
