import XCTest
@testable import Components

final class WKSourceEditorTests: XCTestCase {

    var textView: UITextView!
    var editorView: WKSourceEditorView!
    var editorViewController: WKSourceEditorViewController!

    override func setUpWithError() throws {
        let viewModel = WKSourceEditorViewModel(configuration: .full, initialText: "Testing Wikitext", localizedStrings: WKSourceEditorLocalizedStrings.emptyTestStrings)
        self.editorViewController = WKSourceEditorViewController(viewModel: viewModel, delegate: self)
        editorViewController.loadViewIfNeeded()
        self.editorView = editorViewController.editorView
        self.textView = editorViewController.editorView.textView
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
        editorViewController.editorViewDidTapFind(editorView: editorView)
        XCTAssert(textView.inputAccessoryView is WKFindAndReplaceView)
        editorViewController.closeFind()
        XCTAssert(textView.inputAccessoryView is WKEditorToolbarExpandingView)
    }
}

extension WKSourceEditorTests: WKSourceEditorViewControllerDelegate {
    func sourceEditorViewControllerDidTapFind(sourceEditorViewController: Components.WKSourceEditorViewController) {

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
            accessibilityLabelButtonFormatHeading: "",
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
            accessibilityLabelButtonClearFormatting: "",
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
