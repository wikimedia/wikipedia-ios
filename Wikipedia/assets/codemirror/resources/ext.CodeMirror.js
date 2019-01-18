( function () {
	var useCodeMirror, codeMirror, api, originHooksTextarea, cmTextSelection,
		enableContentEditable = true;

	if ( mw.config.get( 'wgCodeEditorCurrentLanguage' ) ) { // If the CodeEditor is used then just exit;
		return;
	}

	// Exit if WikiEditor is disabled
	// usebetatoolbar can be the string "0" if the user disabled the preference - Bug T54542#555387
	if ( !( mw.loader.getState( 'ext.wikiEditor' ) && mw.user.options.get( 'usebetatoolbar' ) > 0 ) ) {
		return;
	}

	useCodeMirror = mw.user.options.get( 'usecodemirror' ) > 0;
	api = new mw.Api();

	originHooksTextarea = $.valHooks.textarea;
	// define jQuery hook for searching and replacing text using JS if CodeMirror is enabled, see Bug: T108711
	$.valHooks.textarea = {
		get: function ( elem ) {
			if ( elem.id === 'wpTextbox1' && codeMirror ) {
				return codeMirror.doc.getValue();
			} else if ( originHooksTextarea ) {
				return originHooksTextarea.get( elem );
			}
			return elem.value;
		},
		set: function ( elem, value ) {
			if ( elem.id === 'wpTextbox1' && codeMirror ) {
				return codeMirror.doc.setValue( value );
			} else if ( originHooksTextarea ) {
				return originHooksTextarea.set( elem, value );
			}
			elem.value = value;
		}
	};

	// Disable spellchecking for Firefox users on non-Mac systems (Bug T95104)
	if ( navigator.userAgent.indexOf( 'Firefox' ) > -1 &&
		navigator.userAgent.indexOf( 'Mac' ) === -1
	) {
		enableContentEditable = false;
	}

	// T174055: Do not redefine the browser history navigation keys (T175378: for PC only)
	CodeMirror.keyMap.pcDefault[ 'Alt-Left' ] = false;
	CodeMirror.keyMap.pcDefault[ 'Alt-Right' ] = false;

	// jQuery.textSelection overrides for CodeMirror.
	// See jQuery.textSelection.js for method documentation
	cmTextSelection = {
		getContents: function () {
			return codeMirror.doc.getValue();
		},
		setContents: function ( content ) {
			codeMirror.doc.setValue( content );
			return this;
		},
		getSelection: function () {
			return codeMirror.doc.getSelection();
		},
		setSelection: function ( options ) {
			codeMirror.focus();
			codeMirror.doc.setSelection( codeMirror.doc.posFromIndex( options.start ), codeMirror.doc.posFromIndex( options.end ) );
			return this;
		},
		replaceSelection: function ( value ) {
			codeMirror.doc.replaceSelection( value );
			return this;
		},
		getCaretPosition: function ( options ) {
			var caretPos = codeMirror.doc.indexFromPos( codeMirror.doc.getCursor( true ) ),
				endPos = codeMirror.doc.indexFromPos( codeMirror.doc.getCursor( false ) );
			if ( options.startAndEnd ) {
				return [ caretPos, endPos ];
			}
			return caretPos;
		},
		scrollToCaretPosition: function () {
			codeMirror.scrollIntoView( null );
			return this;
		}
	};

	/**
	 * Save CodeMirror enabled pref.
	 *
	 * @param {boolean} prefValue True, if CodeMirror should be enabled by default, otherwise false.
	 */
	function setCodeEditorPreference( prefValue ) {
		useCodeMirror = prefValue; // Save state for function updateToolbarButton()

		if ( mw.user.isAnon() ) { // Skip it for anon users
			return;
		}
		api.saveOption( 'usecodemirror', prefValue ? 1 : 0 );
		mw.user.options.set( 'usecodemirror', prefValue ? 1 : 0 );
	}

	/**
	 * Replaces the default textarea with CodeMirror
	 */
	function enableCodeMirror() {
		var config = mw.config.get( 'extCodeMirrorConfig' );

		mw.loader.using( config.pluginModules, function () {
			var $codeMirror,
				$textbox1 = $( '#wpTextbox1' ),
				selectionStart = $textbox1.prop( 'selectionStart' ),
				selectionEnd = $textbox1.prop( 'selectionEnd' ),
				scrollTop = $textbox1.scrollTop();

			// If CodeMirror is already loaded or wikEd gadget is enabled, abort. See T178348.
			// FIXME: Would be good to replace the wikEd check with something more generic.
			if ( codeMirror || mw.user.options.get( 'gadget-wikEd' ) > 0 ) {
				return;
			}

			codeMirror = CodeMirror.fromTextArea( $textbox1[ 0 ], {
				mwConfig: config,
				// styleActiveLine: true, // disabled since Bug: T162204, maybe should be optional
				lineWrapping: true,
				readOnly: $textbox1[ 0 ].readOnly,
				// select mediawiki as text input mode
				mode: 'text/mediawiki',
				extraKeys: {
					Tab: false,
					'Shift-Tab': false,
					// T174514: Move the cursor at the beginning/end of the current wrapped line
					Home: 'goLineLeft',
					End: 'goLineRight'
				},
				inputStyle: enableContentEditable ? 'contenteditable' : 'textarea',
				spellcheck: enableContentEditable,
				viewportMargin: Infinity
			} );
			$codeMirror = $( codeMirror.getWrapperElement() );

			// Allow textSelection() functions to work with CodeMirror editing field.
			$codeMirror.textSelection( 'register', cmTextSelection );
			// Also override textSelection() functions for the "real" hidden textarea to route to
			// CodeMirror. We unregister this when switching to normal textarea mode.
			$textbox1.textSelection( 'register', cmTextSelection );

			$codeMirror.resizable( {
				handles: 'se',
				resize: function ( event, ui ) {
					ui.size.width = ui.originalSize.width;
				}
			} );

			codeMirror.doc.setSelection( codeMirror.doc.posFromIndex( selectionEnd ), codeMirror.doc.posFromIndex( selectionStart ) );
			codeMirror.scrollTo( null, scrollTop );

			// HACK: <textarea> font size varies by browser (chrome/FF/IE)
			$codeMirror.css( {
				'font-size': $textbox1.css( 'font-size' ),
				'line-height': $textbox1.css( 'line-height' )
			} );

			// use direction and language of the original textbox
			$codeMirror.attr( {
				dir: $textbox1.attr( 'dir' ),
				lang: $textbox1.attr( 'lang' )
			} );

			// T194102: UniversalLanguageSelector integration is buggy, disabling it completely
			$( codeMirror.getInputField() ).addClass( 'noime' );

			// set the height of the textarea
			codeMirror.setSize( null, $textbox1.height() );
		} );
	}

	/**
	 * Updates CodeMirror button on the toolbar according to the current state (on/off)
	 */
	function updateToolbarButton() {
		var $button = $( '#mw-editbutton-codemirror' );

		$button.toggleClass( 'mw-editbutton-codemirror-active', !!useCodeMirror );

		// WikiEditor2010 OOUI ToggleButtonWidget
		if ( $button.data( 'setActive' ) ) {
			$button.data( 'setActive' )( !!useCodeMirror );
		}
	}

	/**
	 * Enables or disables CodeMirror
	 */
	function switchCodeMirror() {
		var selectionObj, selectionStart, selectionEnd, scrollTop, hasFocus, $codeMirror,
			$textbox1 = $( '#wpTextbox1' );

		if ( codeMirror ) {
			scrollTop = codeMirror.getScrollInfo().top;
			selectionObj = codeMirror.doc.listSelections()[ 0 ];
			selectionStart = codeMirror.doc.indexFromPos( selectionObj.head );
			selectionEnd = codeMirror.doc.indexFromPos( selectionObj.anchor );
			hasFocus = codeMirror.hasFocus();
			$codeMirror = $( codeMirror.getWrapperElement() );
			setCodeEditorPreference( false );
			$codeMirror.textSelection( 'unregister' );
			$textbox1.textSelection( 'unregister' );
			codeMirror.toTextArea();
			codeMirror = null;
			if ( hasFocus ) {
				$textbox1.focus();
			}
			$textbox1.prop( 'selectionStart', selectionStart );
			$textbox1.prop( 'selectionEnd', selectionEnd );
			$textbox1.scrollTop( scrollTop );
		} else {
			enableCodeMirror();
			setCodeEditorPreference( true );
		}
		updateToolbarButton();
	}

	/**
	 * Adds the CodeMirror button to WikiEditor
	 */
	function addCodeMirrorToWikiEditor() {
		var $codeMirrorButton;

		$( '#wpTextbox1' ).wikiEditor(
			'addToToolbar',
			{
				section: 'main',
				groups: {
					codemirror: {
						tools: {
							CodeMirror: {
								label: mw.msg( 'codemirror-toggle-label' ),
								type: 'toggle',
								oouiIcon: 'highlight',
								action: {
									type: 'callback',
									execute: function () {
										switchCodeMirror();
									}
								}
							}
						}
					}
				}
			}
		);

		$codeMirrorButton = $( '#wpTextbox1' ).data( 'wikiEditor-context' ).modules.toolbar.$toolbar.find( '.tool[rel=CodeMirror]' );
		$codeMirrorButton
			.attr( 'id', 'mw-editbutton-codemirror' );

		updateToolbarButton();
	}

	/**
	 * Adds CodeMirror button to the toolbar
	 */
	function addToolbarButton() {
		// They are using WikiEditor
		mw.loader.using( 'ext.wikiEditor', function () {
			// Add CodeMirror button to the enhanced editing toolbar.
			$( addCodeMirrorToWikiEditor );
		} );
	}

	// If view is in edit mode, add the button to the toolbar.
	if ( $( '#wpTextbox1' ).length ) {
		addToolbarButton();
	}

	// enable CodeMirror
	if ( useCodeMirror ) {
		$( '#wpTextbox1' ).on( 'wikiEditor-toolbar-doneInitialSections', enableCodeMirror.bind( this ) );
	}

	// Synchronize textarea with CodeMirror before leaving
	window.addEventListener( 'beforeunload', function () {
		if ( codeMirror ) {
			codeMirror.save();
		}
	} );

}() );
