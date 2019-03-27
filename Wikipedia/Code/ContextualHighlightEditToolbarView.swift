class ContextualHighlightEditToolbarView: EditToolbarView {
    @IBOutlet private weak var stackView: UIStackView!
    @IBOutlet private weak var showMoreButton: TextFormattingButton!

    override func awakeFromNib() {
        super.awakeFromNib()
        stackView.isLayoutMarginsRelativeArrangement = true
        stackView.layoutMargins = UIEdgeInsets(top: 5, left: 0, bottom: 5, right: 0)

        showMoreButton.tintColorKeyPath = \Theme.colors.link
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

    @IBAction private func toggleReferenceSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapReference()
    }

    @IBAction private func toggleAnchorSelection(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapLink()
    }

    @IBAction private func toggleTemplate(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTemplate()
    }

    @IBAction private func clearFormatting(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapClearFormatting()
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTextFormatting()
    }
}
