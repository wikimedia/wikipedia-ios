/*!
 * VisualEditor UserInterface CodeMirrorAction class.
 *
 * @copyright 2011-2017 VisualEditor Team and others; see http://ve.mit-license.org
 */

/**
 * CodeMirror action
 *
 * @class
 * @extends ve.ui.Action
 * @constructor
 * @param {ve.ui.Surface} surface Surface to act on
 */
ve.ui.CodeMirrorAction = function VeUiCodeMirrorAction() {
	// Parent constructor
	ve.ui.CodeMirrorAction.super.apply( this, arguments );
};

/* Inheritance */

OO.inheritClass( ve.ui.CodeMirrorAction, ve.ui.Action );

/* Static Properties */

ve.ui.CodeMirrorAction.static.name = 'codeMirror';

/**
 * @inheritdoc
 */
ve.ui.CodeMirrorAction.static.methods = [ 'toggle' ];

/* Static methods */

/**
 * Make whitespace replacements to match ve.ce.TextNode functionality
 *
 * @param {string} text Text
 * @return {string} Replaced text
 */
ve.ui.CodeMirrorAction.static.fixWhitespace = ( function () {
	var ws, symbol, pattern,
		visibleWhitespaceCharacters = ve.visibleWhitespaceCharacters,
		replacements = [];

	// Convert visibleWhitespaceCharacters object into regex/symbol
	// pairs and cache result locally.
	for ( ws in visibleWhitespaceCharacters ) {
		// We actally render newlines
		if ( ws !== '\n' ) {
			symbol = visibleWhitespaceCharacters[ ws ];
			pattern = new RegExp( ws, 'g' );
			replacements.push( [ pattern, symbol ] );
		}
	}

	return function fixWhitespace( text ) {
		replacements.forEach( function ( replacement ) {
			text = text.replace( replacement[ 0 ], replacement[ 1 ] );
		} );
		return text;
	};

}() );

/* Methods */

/**
 * @method
 * @param {boolean} [enable] State to force toggle to, inverts current state if undefined
 * @return {boolean} Action was executed
 */
ve.ui.CodeMirrorAction.prototype.toggle = function ( enable ) {
	var profile, supportsTransparentText, mirrorElement,
		surface = this.surface,
		surfaceView = surface.getView(),
		doc = surface.getModel().getDocument();

	if ( !surface.mirror && enable !== false ) {
		surface.mirror = CodeMirror( surfaceView.$element[ 0 ], {
			value: this.constructor.static.fixWhitespace( surface.getDom() ),
			mwConfig: mw.config.get( 'extCodeMirrorConfig' ),
			readOnly: 'nocursor',
			lineWrapping: true,
			scrollbarStyle: 'null',
			specialChars: /^$/,
			viewportMargin: 5,
			// select mediawiki as text input mode
			mode: 'text/mediawiki',
			extraKeys: {
				Tab: false,
				'Shift-Tab': false
			}
		} );

		// The VE/CM overlay technique only works with monospace fonts (as we use width-changing bold as a highlight)
		// so revert any editfont user preference
		surfaceView.$element.removeClass( 'mw-editfont-sans-serif mw-editfont-serif' ).addClass( 'mw-editfont-monospace' );

		profile = $.client.profile();
		supportsTransparentText = 'WebkitTextFillColor' in document.body.style &&
			// Disable on Firefox+OSX (T175223)
			!( profile.layout === 'gecko' && profile.platform === 'mac' );

		surfaceView.$documentNode.addClass(
			supportsTransparentText ?
				've-ce-documentNode-codeEditor-webkit-hide' :
				've-ce-documentNode-codeEditor-hide'
		);

		/* Events */

		// As the action is regenerated each time, we need to store bound listeners
		// in the mirror for later disconnection.
		surface.mirror.veTransactionListener = this.onDocumentPrecommit.bind( this );
		surface.mirror.veLangChangeListener = this.onLangChange.bind( this );

		doc.on( 'precommit', surface.mirror.veTransactionListener );
		surfaceView.getDocument().on( 'langChange', surface.mirror.veLangChangeListener );

		this.onLangChange();

		ve.init.target.once( 'surfaceReady', function () {
			if ( surface.mirror ) {
				surface.mirror.refresh();
			}
		} );

	} else if ( surface.mirror && enable !== true ) {
		doc.off( 'precommit', surface.mirror.veTransactionListener );
		surfaceView.getDocument().off( 'langChange', surface.mirror.veLangChangeListener );

		// Restore edit-font
		surfaceView.$element.removeClass( 'mw-editfont-monospace' ).addClass( 'mw-editfont-' + mw.user.options.get( 'editfont' ) );

		surfaceView.$documentNode.removeClass(
			've-ce-documentNode-codeEditor-webkit-hide ve-ce-documentNode-codeEditor-hide'
		);

		mirrorElement = surface.mirror.getWrapperElement();
		mirrorElement.parentNode.removeChild( mirrorElement );

		surface.mirror = null;
	}

	return true;
};

/**
 * Handle langChange events from the document view
 */
ve.ui.CodeMirrorAction.prototype.onLangChange = function () {
	var surface = this.surface,
		dir = surface.getView().getDocument().getDir();

	surface.mirror.setOption( 'direction', dir );
};

/**
 * Handle precommit events from the document.
 *
 * The document is still in it's 'old' state before the transaction
 * has been applied at this point.
 *
 * @param {ve.dm.Transaction} tx [description]
 */
ve.ui.CodeMirrorAction.prototype.onDocumentPrecommit = function ( tx ) {
	var i,
		offset = 0,
		replacements = [],
		linearData = this.surface.getModel().getDocument().data,
		store = linearData.getStore(),
		mirror = this.surface.mirror,
		fixWhitespace = this.constructor.static.fixWhitespace;

	/**
	 * Convert a VE offset to a 2D CodeMirror position
	 *
	 * @private
	 * @param {number} veOffset VE linear model offset
	 * @return {Object} Code mirror position, containing 'line' and 'ch'
	 */
	function convertOffset( veOffset ) {
		var cmOffset = linearData.getSourceText( new ve.Range( 0, veOffset ) ).length;
		return mirror.posFromIndex( cmOffset );
	}

	tx.operations.forEach( function ( op ) {
		if ( op.type === 'retain' ) {
			offset += op.length;
		} else if ( op.type === 'replace' ) {
			replacements.push( {
				start: convertOffset( offset ),
				// Don't bother recalculating end offset if not a removal, replaceRange works with just one arg
				end: op.remove.length ? convertOffset( offset + op.remove.length ) : undefined,
				data: fixWhitespace( new ve.dm.ElementLinearData( store, op.insert ).getSourceText() )
			} );
			offset += op.remove.length;
		}
	} );

	// Apply replacements in reverse to avoid having to shift offsets
	for ( i = replacements.length - 1; i >= 0; i-- ) {
		mirror.replaceRange(
			replacements[ i ].data,
			replacements[ i ].start,
			replacements[ i ].end
		);
	}

	// HACK: The absolutely positioned CodeMirror doesn't calculate the viewport
	// correctly when expanding from less than the viewport height.  (T185184)
	if ( mirror.display.sizer.style.minHeight !== this.lastHeight ) {
		mirror.refresh();
	}
	this.lastHeight = mirror.display.sizer.style.minHeight;
};

/* Registration */

ve.ui.actionFactory.register( ve.ui.CodeMirrorAction );
