import XCTest
@testable import Components

final class WKSourceEditorTests: XCTestCase {

    var textView: UITextView!
    var editorViewController: WKSourceEditorViewController!

    override func setUpWithError() throws {
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "Testing Wikitext", localizedStrings: WKSourceEditorLocalizedStrings.emptyTestStrings, isSyntaxHighlightingEnabled: true, textAlignment: .left)
        self.editorViewController = WKSourceEditorViewController(viewModel: viewModel, delegate: self)
        editorViewController.loadViewIfNeeded()
        self.textView = editorViewController.textView
    }

    func testSourceEditorDefaultInputAccessoryView() {
        textView.becomeFirstResponder()
        XCTAssert(textView.inputAccessoryView is WKEditorToolbarExpandingView)
    }

    func testSourceEditorHighlightInputAccessoryView() {
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: 0, length: 7)
        XCTAssert(textView.inputAccessoryView is WKEditorToolbarHighlightView)
    }

    func testSourceEditorFindInputAccessoryView() {
        textView.becomeFirstResponder()
        editorViewController.toolbarExpandingViewDidTapFind(toolbarView: editorViewController.expandingAccessoryView)
        XCTAssert(textView.inputAccessoryView is WKFindAndReplaceView)
        editorViewController.closeFind()
        XCTAssert(textView.inputAccessoryView is WKEditorToolbarExpandingView)
    }
}

extension WKSourceEditorTests: WKSourceEditorViewControllerDelegate {
    func sourceEditorDidChangeUndoState(_ sourceEditorViewController: Components.WKSourceEditorViewController, canUndo: Bool, canRedo: Bool) {
        
    }
    
    func sourceEditorDidChangeText(_ sourceEditorViewController: Components.WKSourceEditorViewController, didChangeText: Bool) {
        
    }
    
    func sourceEditorViewControllerDidRemoveFindInputAccessoryView(_ sourceEditorViewController: Components.WKSourceEditorViewController) {
        
    }
    
    func sourceEditorViewControllerDidTapFind(_ sourceEditorViewController: Components.WKSourceEditorViewController) {

    }
    
    func sourceEditorViewControllerDidTapLink(parameters: Components.WKSourceEditorFormatterLinkWizardParameters) {
        
    }
    
    func sourceEditorViewControllerDidTapImage() {
        
    }
}

extension WKSourceEditorLocalizedStrings {
    static var emptyTestStrings: WKSourceEditorLocalizedStrings {
        return WKSourceEditorLocalizedStrings(
            inputViewTextFormatting: "",
            inputViewStyle: "",
            inputViewClearFormatting: "",
            inputViewParagraph: "",
            inputViewHeading: "",
            inputViewSubheading1: "",
            inputViewSubheading2: "",
            inputViewSubheading3: "",
            inputViewSubheading4: "",
            findReplaceTypeSingle: "",
            findReplaceTypeAll: "",
            findReplaceWith: "",
            accessibilityLabelButtonFormatText: "",
            accessibilityLabelButtonCitation: "",
            accessibilityLabelButtonCitationSelected: "",
            accessibilityLabelButtonLink: "",
            accessibilityLabelButtonLinkSelected: "",
            accessibilityLabelButtonTemplate: "",
            accessibilityLabelButtonTemplateSelected: "",
            accessibilityLabelButtonMedia: "",
            accessibilityLabelButtonFind: "",
            accessibilityLabelButtonListUnordered: "",
            accessibilityLabelButtonListUnorderedSelected: "",
            accessibilityLabelButtonListOrdered: "",
            accessibilityLabelButtonListOrderedSelected: "",
            accessibilityLabelButtonInceaseIndent: "",
            accessibilityLabelButtonDecreaseIndent: "",
            accessibilityLabelButtonCursorUp: "",
            accessibilityLabelButtonCursorDown: "",
            accessibilityLabelButtonCursorLeft: "",
            accessibilityLabelButtonCursorRight: "",
            accessibilityLabelButtonBold: "",
            accessibilityLabelButtonBoldSelected: "",
            accessibilityLabelButtonItalics: "",
            accessibilityLabelButtonItalicsSelected: "",
            accessibilityLabelButtonShowMore: "",
            accessibilityLabelButtonComment: "",
            accessibilityLabelButtonCommentSelected: "",
            accessibilityLabelButtonSuperscript: "",
            accessibilityLabelButtonSuperscriptSelected: "",
            accessibilityLabelButtonSubscript: "",
            accessibilityLabelButtonSubscriptSelected: "",
            accessibilityLabelButtonUnderline: "",
            accessibilityLabelButtonUnderlineSelected: "",
            accessibilityLabelButtonStrikethrough: "",
            accessibilityLabelButtonStrikethroughSelected:  "",
            accessibilityLabelButtonCloseMainInputView: "",
            accessibilityLabelButtonCloseHeaderSelectInputView: "",
            accessibilityLabelFindTextField: "",
            accessibilityLabelFindButtonClear: "",
            accessibilityLabelFindButtonClose: "",
            accessibilityLabelFindButtonNext: "",
            accessibilityLabelFindButtonPrevious: "",
            accessibilityLabelReplaceTextField:  "",
            accessibilityLabelReplaceButtonClear: "",
            accessibilityLabelReplaceButtonPerformFormat: "",
            accessibilityLabelReplaceButtonSwitchFormat: "",
            accessibilityLabelReplaceTypeSingle: "",
            accessibilityLabelReplaceTypeAll: ""
        )
    }
}
