/**
 * MediaWiki UserInterface CodeMirror tool.
 *
 * @class
 * @abstract
 * @extends ve.ui.Tool
 * @constructor
 * @param {OO.ui.ToolGroup} toolGroup
 * @param {Object} [config] Configuration options
 */
ve.ui.CodeMirrorTool = function VeUiCodeMirrorTool() {
	// Parent constructor
	ve.ui.CodeMirrorTool.super.apply( this, arguments );

	// Events
	this.toolbar.connect( this, { surfaceChange: 'onSurfaceChange' } );
};

/* Inheritance */

OO.inheritClass( ve.ui.CodeMirrorTool, ve.ui.Tool );

/* Static properties */

ve.ui.CodeMirrorTool.static.name = 'codeMirror';
ve.ui.CodeMirrorTool.static.autoAddToCatchall = false;
ve.ui.CodeMirrorTool.static.title = OO.ui.deferMsg( 'codemirror-toggle-label' );
ve.ui.CodeMirrorTool.static.icon = 'highlight';
ve.ui.CodeMirrorTool.static.group = 'codeMirror';
ve.ui.CodeMirrorTool.static.commandName = 'codeMirror';
ve.ui.CodeMirrorTool.static.deactivateOnSelect = false;

/**
 * @inheritdoc
 */
ve.ui.CodeMirrorTool.prototype.onSelect = function () {
	var useCodeMirror;

	// Parent method
	ve.ui.CodeMirrorTool.super.prototype.onSelect.apply( this, arguments );

	useCodeMirror = !!this.toolbar.surface.mirror;
	this.setActive( useCodeMirror );

	new mw.Api().saveOption( 'usecodemirror', useCodeMirror ? 1 : 0 );
	mw.user.options.set( 'usecodemirror', useCodeMirror ? 1 : 0 );
};

/**
 * @inheritdoc
 */
ve.ui.CodeMirrorTool.prototype.onSurfaceChange = function ( oldSurface, newSurface ) {
	var useCodeMirror,
		isDisabled = newSurface.getMode() !== 'source',
		command = this.getCommand(),
		surface = this.toolbar.getSurface();

	this.setDisabled( isDisabled );
	if ( !isDisabled ) {
		useCodeMirror = mw.user.options.get( 'usecodemirror' ) > 0;
		command.execute( surface, [ useCodeMirror ] );
		this.setActive( useCodeMirror );
	}
};

ve.ui.CodeMirrorTool.prototype.onUpdateState = function () {};

/* Registration */

ve.ui.toolFactory.register( ve.ui.CodeMirrorTool );

/* Command */

ve.ui.commandRegistry.register(
	new ve.ui.Command(
		'codeMirror', 'codeMirror', 'toggle'
	)
);
