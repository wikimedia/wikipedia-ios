class TextFormattingPlainToolbarView: TextFormattingToolbarView {

    @IBAction private func toggleBold(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapBold()
    }

    @IBAction private func toggleItalics(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapItalics()
    }

    @IBAction private func toggleReference(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapReference()
    }

    @IBAction private func toggleTemplate(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapTemplate()
    }

    @IBAction private func toggleComment(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapComment()
    }

    @IBAction private func toggleLink(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapLink()
    }
}
