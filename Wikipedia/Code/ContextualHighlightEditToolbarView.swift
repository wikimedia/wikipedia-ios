class ContextualHighlightEditToolbarView: EditToolbarView {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var showMoreButton: TextFormattingButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)
    }

    @IBAction private func toggleBoldSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapBold()
    }

    @IBAction private func toggleItalicSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapItalics()
    }

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextStyleFormatting()
    }

    @IBAction private func removeSelectionFormatting(_ sender: UIButton) {
        //
    }

    @IBAction private func toggleReferenceSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapReference()
    }

    @IBAction private func toggleAnchorSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapLink()
    }

    @IBAction private func toggleUnorderedListSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapUnorderedList()
    }

    @IBAction private func toggleOrderedListSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapOrderedList()
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextFormatting()
    }
}
