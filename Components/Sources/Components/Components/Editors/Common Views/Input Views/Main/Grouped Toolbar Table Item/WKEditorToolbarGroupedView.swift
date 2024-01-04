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
    
    weak var delegate: WKEditorInputViewDelegate?
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()

        unorderedListButton.setImage(WKSFSymbolIcon.for(symbol: .listBullet), for: .normal)
        unorderedListButton.addTarget(self, action: #selector(tappedUnorderedList), for: .touchUpInside)
        unorderedListButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonListUnordered

        orderedListButton.setImage(WKSFSymbolIcon.for(symbol: .listNumber), for: .normal)
        orderedListButton.addTarget(self, action: #selector(tappedOrderedList), for: .touchUpInside)
        orderedListButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonListOrdered

        decreaseIndentButton.setImage(WKSFSymbolIcon.for(symbol: .decreaseIndent), for: .normal)
        decreaseIndentButton.addTarget(self, action: #selector(tappedDecreaseIndent), for: .touchUpInside)
        decreaseIndentButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonDecreaseIndent

        increaseIndentButton.setImage(WKSFSymbolIcon.for(symbol: .increaseIndent), for: .normal)
        increaseIndentButton.addTarget(self, action: #selector(tappedIncreaseIndent), for: .touchUpInside)
        increaseIndentButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonInceaseIndent

        superscriptButton.setImage(WKSFSymbolIcon.for(symbol: .textFormatSuperscript), for: .normal)
        superscriptButton.addTarget(self, action: #selector(tappedSuperscript), for: .touchUpInside)
        superscriptButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonSuperscript

        subscriptButton.setImage(WKSFSymbolIcon.for(symbol: .textFormatSubscript), for: .normal)
        subscriptButton.addTarget(self, action: #selector(tappedSubscript), for: .touchUpInside)
        subscriptButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonSubscript

        underlineButton.setImage(WKSFSymbolIcon.for(symbol: .underline), for: .normal)
        underlineButton.addTarget(self, action: #selector(tappedUnderline), for: .touchUpInside)
        underlineButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonUnderline

        strikethroughButton.setImage(WKSFSymbolIcon.for(symbol: .strikethrough), for: .normal)
        strikethroughButton.addTarget(self, action: #selector(tappedStrikethrough), for: .touchUpInside)
        strikethroughButton.accessibilityLabel = WKSourceEditorLocalizedStrings.current?.accessibilityLabelButtonStrikethrough
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateButtonSelectionState(_:)), name: Notification.WKSourceEditorSelectionState, object: nil)
    }
    
    // MARK: - Notifications
        
    @objc private func updateButtonSelectionState(_ notification: NSNotification) {
        guard let selectionState = notification.userInfo?[Notification.WKSourceEditorSelectionStateKey] as? WKSourceEditorSelectionState else {
            return
        }

        strikethroughButton.isSelected = selectionState.isStrikethrough
        subscriptButton.isSelected = selectionState.isSubscript
        superscriptButton.isSelected = selectionState.isSuperscript
        underlineButton.isSelected = selectionState.isUnderline
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
        delegate?.didTapSuperscript(isSelected: superscriptButton.isSelected)
    }
    
    @objc private func tappedSubscript() {
        delegate?.didTapSubscript(isSelected: subscriptButton.isSelected)
    }
    
    @objc private func tappedUnderline() {
        delegate?.didTapUnderline(isSelected: underlineButton.isSelected)
    }
    
    @objc private func tappedStrikethrough() {
        delegate?.didTapStrikethrough(isSelected: strikethroughButton.isSelected)
    }
    
}
