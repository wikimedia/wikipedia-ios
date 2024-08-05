import XCTest
@testable import WMFComponents

final class WMFSourceEditorTests: XCTestCase {

    var textView: UITextView!
    var editorViewController: WMFSourceEditorViewController!

    override func setUpWithError() throws {
        let viewModel = WMFSourceEditorViewModel(configuration: .full, initialText: "Testing Wikitext", localizedStrings: WMFSourceEditorLocalizedStrings.emptyTestStrings, isSyntaxHighlightingEnabled: true, textAlignment: .left, needsReadOnly: false, onloadSelectRange: nil)
        self.editorViewController = WMFSourceEditorViewController(viewModel: viewModel, delegate: self)
        editorViewController.loadViewIfNeeded()
        self.textView = editorViewController.textView
    }

    func testSourceEditorDefaultInputAccessoryView() {
        textView.becomeFirstResponder()
        XCTAssert(textView.inputAccessoryView is WMFEditorToolbarExpandingView)
    }

    func testSourceEditorHighlightInputAccessoryView() {
        textView.becomeFirstResponder()
        textView.selectedRange = NSRange(location: 0, length: 7)
        XCTAssert(textView.inputAccessoryView is WMFEditorToolbarHighlightView)
    }

    func testSourceEditorFindInputAccessoryView() {
        textView.becomeFirstResponder()
        editorViewController.toolbarExpandingViewDidTapFind(toolbarView: editorViewController.expandingAccessoryView)
        XCTAssert(textView.inputAccessoryView is WMFFindAndReplaceView)
        editorViewController.closeFind()
        XCTAssert(textView.inputAccessoryView is WMFEditorToolbarExpandingView)
    }
}

extension WMFSourceEditorTests: WMFSourceEditorViewControllerDelegate {
    func sourceEditorDidChangeUndoState(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController, canUndo: Bool, canRedo: Bool) {

    }
    
    func sourceEditorDidChangeText(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController, didChangeText: Bool) {

    }
    
    func sourceEditorViewControllerDidRemoveFindInputAccessoryView(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController) {

    }
    
    func sourceEditorViewControllerDidTapFind(_ sourceEditorViewController: WMFComponents.WMFSourceEditorViewController) {

    }
    
    func sourceEditorViewControllerDidTapLink(parameters: WMFComponents.WMFSourceEditorFormatterLinkWizardParameters) {
        
    }
    
    func sourceEditorViewControllerDidTapImage() {
        
    }
}

extension WMFSourceEditorLocalizedStrings {
    static var emptyTestStrings: WMFSourceEditorLocalizedStrings {
        return WMFSourceEditorLocalizedStrings(keyboardTextFormattingTitle: "",
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
