import Foundation

public struct WMFSourceEditorAccessibilityIdentifiers {

    static var current: WMFSourceEditorAccessibilityIdentifiers?

    public init(textView: String, findButton: String, showMoreButton: String, closeButton: String, formatTextButton: String, expandingToolbar: String, highlightToolbar: String, findToolbar: String, inputView: String) {
        self.textView = textView
        self.findButton = findButton
        self.showMoreButton = showMoreButton
        self.closeButton = closeButton
        self.formatTextButton = formatTextButton
        self.expandingToolbar = expandingToolbar
        self.highlightToolbar = highlightToolbar
        self.findToolbar = findToolbar
        self.inputView = inputView
    }

    let textView: String
    let findButton: String
    let showMoreButton: String
    let closeButton: String
    let formatTextButton: String
    let expandingToolbar: String
    let highlightToolbar: String
    let findToolbar: String
    let inputView: String
}
