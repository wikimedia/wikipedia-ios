import Foundation

public struct WKSourceEditorAccessibilityIdentifiers {

    static var current: WKSourceEditorAccessibilityIdentifiers?

    public init(textView: String, findButton: String, showMoreButton: String, closeButton: String, formatTextButton: String, formatHeadingButton: String, expandingToolbar: String, highlightToolbar: String, findToolbar: String, mainInputView: String, headerSelectInputView: String) {
        self.textView = textView
        self.findButton = findButton
        self.showMoreButton = showMoreButton
        self.closeButton = closeButton
        self.formatTextButton = formatTextButton
        self.formatHeadingButton = formatHeadingButton
        self.expandingToolbar = expandingToolbar
        self.highlightToolbar = highlightToolbar
        self.findToolbar = findToolbar
        self.mainInputView = mainInputView
        self.headerSelectInputView = headerSelectInputView
    }

    let textView: String
    let findButton: String
    let showMoreButton: String
    let closeButton: String
    let formatTextButton: String
    let formatHeadingButton: String
    let expandingToolbar: String
    let highlightToolbar: String
    let findToolbar: String
    let mainInputView: String
    let headerSelectInputView: String
}
