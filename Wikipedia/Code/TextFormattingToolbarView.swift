class TextFormattingToolbarView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    @IBAction private func toggleBold(_ sender: UIButton) {
        delegate?.textFormattingProvidingDidTapBoldButton(self, button: sender)
    }

    @IBAction private func toggleItalics(sender: UIButton) {
        delegate?.textFormattingProvidingDidTapItalicsButton(self, button: sender)
    }
}

extension TextFormattingToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
