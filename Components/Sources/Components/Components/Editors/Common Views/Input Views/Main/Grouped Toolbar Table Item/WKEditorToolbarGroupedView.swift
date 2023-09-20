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
        
        orderedListButton.setImage(WKIcon.listOrdered, for: .normal)
        orderedListButton.addTarget(self, action: #selector(tappedOrderedList), for: .touchUpInside)
        
        decreaseIndentButton.setImage(WKIcon.indentDecrease, for: .normal)
        decreaseIndentButton.addTarget(self, action: #selector(tappedDecreaseIndent), for: .touchUpInside)
        
        increaseIndentButton.setImage(WKIcon.indentIncrease, for: .normal)
        increaseIndentButton.addTarget(self, action: #selector(tappedIncreaseIndent), for: .touchUpInside)
        
        superscriptButton.setImage(WKIcon.superscript, for: .normal)
        superscriptButton.addTarget(self, action: #selector(tappedSuperscript), for: .touchUpInside)
        
        subscriptButton.setImage(WKIcon.subscript, for: .normal)
        subscriptButton.addTarget(self, action: #selector(tappedSubscript), for: .touchUpInside)
        
        underlineButton.setImage(WKIcon.underline, for: .normal)
        underlineButton.addTarget(self, action: #selector(tappedUnderline), for: .touchUpInside)
        
        strikethroughButton.setImage(WKIcon.strikethrough, for: .normal)
        strikethroughButton.addTarget(self, action: #selector(tappedStrikethrough), for: .touchUpInside)
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
