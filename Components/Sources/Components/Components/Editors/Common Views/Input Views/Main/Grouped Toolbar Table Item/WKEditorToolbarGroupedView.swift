import Foundation

class WKEditorToolbarGroupedView: WKEditorToolbarView {
    
    // MARK: - Properties
    
    @IBOutlet private weak var unorderedListButton: WKEditorToolbarButton!
    @IBOutlet private weak var orderedListButton: WKEditorToolbarButton!
    @IBOutlet private weak var decreaseIndentButton: WKEditorToolbarButton!
    @IBOutlet private weak var increaseIndentButton: WKEditorToolbarButton!
    @IBOutlet private weak var superscriptButton: WKEditorToolbarButton!
    @IBOutlet private weak var subscriptButton: WKEditorToolbarButton!
    @IBOutlet private weak var underlineButton: WKEditorToolbarButton!
    @IBOutlet private weak var strikethroughButton: WKEditorToolbarButton!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        unorderedListButton.setImage(WKIcon.listUnordered, for: .normal)
        unorderedListButton.addTarget(self, action: #selector(tappedUnorderedList), for: .touchUpInside)
        unorderedListButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonListUnordered

        orderedListButton.setImage(WKIcon.listOrdered, for: .normal)
        orderedListButton.addTarget(self, action: #selector(tappedOrderedList), for: .touchUpInside)
        orderedListButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonListOrdered

        decreaseIndentButton.setImage(WKIcon.indentDecrease, for: .normal)
        decreaseIndentButton.addTarget(self, action: #selector(tappedDecreaseIndent), for: .touchUpInside)
        decreaseIndentButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonDecreaseIndent

        increaseIndentButton.setImage(WKIcon.indentIncrease, for: .normal)
        increaseIndentButton.addTarget(self, action: #selector(tappedIncreaseIndent), for: .touchUpInside)
        increaseIndentButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonInceaseIndent

        superscriptButton.setImage(WKIcon.superscript, for: .normal)
        superscriptButton.addTarget(self, action: #selector(tappedSuperscript), for: .touchUpInside)
        superscriptButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonSuperscript

        subscriptButton.setImage(WKIcon.subscript, for: .normal)
        subscriptButton.addTarget(self, action: #selector(tappedSubscript), for: .touchUpInside)
        subscriptButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonSubscript

        underlineButton.setImage(WKIcon.underline, for: .normal)
        underlineButton.addTarget(self, action: #selector(tappedUnderline), for: .touchUpInside)
        underlineButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonUnderline

        strikethroughButton.setImage(WKIcon.strikethrough, for: .normal)
        strikethroughButton.addTarget(self, action: #selector(tappedStrikethrough), for: .touchUpInside)
        strikethroughButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonStrikethrough
    }
    
    // MARK: - Button Actions
    
    @objc private func tappedIncreaseIndent() {
    }
    
    @objc private func tappedDecreaseIndent() {
    }
    
    @objc private func tappedUnorderedList() {
    }
    
    @objc private func tappedOrderedList() {
    }
    
    @objc private func tappedSuperscript() {
    }
    
    @objc private func tappedSubscript() {
    }
    
    @objc private func tappedUnderline() {
    }
    
    @objc private func tappedStrikethrough() {
    }
    
}
