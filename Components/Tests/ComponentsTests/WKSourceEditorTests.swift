import XCTest
@testable import Components

final class WKSourceEditorTests: XCTestCase {

    var textView: UITextView!
    var editorViewController: WKSourceEditorViewController!

    override func setUpWithError() throws {
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "Testing Wikitext", localizedStrings: WKSourceEditorLocalizedStrings.emptyTestStrings, isSyntaxHighlightingEnabled: true, textAlignment: .left, needsReadOnly: false, onloadSelectRange: nil)
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
        return WKSourceEditorLocalizedStrings(keyboardTextFormattingTitle: "",
                                              keyboardParagraph: "",
                                              keyboardHeading: "",
                                              keyboardSubheading1: "",
                                              keyboardSubheading2: "",
                                              keyboardSubheading3: "",
                                              keyboardSubheading4: "",
                                              findAndReplaceTitle: "",
                                              replaceTypeSingle: "",
                                              replaceTypeAll: "",
                                              replaceTextfieldPlaceholder: "",
                                              replaceTypeContextMenuTitle: "",
                                              toolbarOpenTextFormatMenuButtonAccessibility: "",
                                              toolbarReferenceButtonAccessibility: "",
                                              toolbarLinkButtonAccessibility: "",
                                              toolbarTemplateButtonAccessibility: "",
                                              toolbarImageButtonAccessibility: "",
                                              toolbarFindButtonAccessibility: "",
                                              toolbarExpandButtonAccessibility: "",
                                              toolbarListUnorderedButtonAccessibility: "",
                                              toolbarListOrderedButtonAccessibility: "",
                                              toolbarIndentIncreaseButtonAccessibility: "",
                                              toolbarIndentDecreaseButtonAccessibility: "",
                                              toolbarCursorUpButtonAccessibility: "",
                                              toolbarCursorDownButtonAccessibility: "",
                                              toolbarCursorPreviousButtonAccessibility: "",
                                              toolbarCursorNextButtonAccessibility: "",
                                              toolbarBoldButtonAccessibility: "",
                                              toolbarItalicsButtonAccessibility: "",
                                              keyboardCloseTextFormatMenuButtonAccessibility: "",
                                              keyboardBoldButtonAccessibility: "",
                                              keyboardItalicsButtonAccessibility: "",
                                              keyboardUnderlineButtonAccessibility: "",
                                              keyboardStrikethroughButtonAccessibility: "",
                                              keyboardReferenceButtonAccessibility: "",
                                              keyboardLinkButtonAccessibility: "",
                                              keyboardListUnorderedButtonAccessibility: "",
                                              keyboardListOrderedButtonAccessibility: "",
                                              keyboardIndentIncreaseButtonAccessibility: "",
                                              keyboardIndentDecreaseButtonAccessibility: "",
                                              keyboardSuperscriptButtonAccessibility: "",
                                              keyboardSubscriptButtonAccessibility: "",
                                              keyboardTemplateButtonAccessibility: "",
                                              keyboardCommentButtonAccessibility: "", 
                                              wikitextEditorAccessibility: "", 
                                              wikitextEditorLoadingAccessibility: "",
                                              findTextFieldAccessibility: "",
                                              findClearButtonAccessibility: "",
                                              findCurrentMatchInfoFormatAccessibility: "",
                                              findCurrentMatchInfoZeroResultsAccessibility: "",
                                              findCloseButtonAccessibility: "",
                                              findNextButtonAccessibility: "",
                                              findPreviousButtonAccessibility: "",
                                              replaceTextFieldAccessibility: "",
                                              replaceClearButtonAccessibility: "",
                                              replaceButtonAccessibilityFormat: "",
                                              replaceTypeButtonAccessibilityFormat: "",
                                              replaceTypeSingleAccessibility: "",
                                              replaceTypeAllAccessibility: ""
        )
    }
}
