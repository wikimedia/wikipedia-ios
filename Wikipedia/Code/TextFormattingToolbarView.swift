protocol TextFormattingToolbarViewDelegate: class {
    func textFormattingToolbarViewDidTapBoldButton(_ textFormattingToolbarView: TextFormattingToolbarView, button: UIButton)
}

class TextFormattingToolbarView: UIView {
    weak var delegate: TextFormattingToolbarViewDelegate?

    @IBAction private func toggleBold(_ sender: UIButton) {
        delegate?.textFormattingToolbarViewDidTapBoldButton(self, button: sender)
    }
}

extension TextFormattingToolbarView: Themeable {
    func apply(theme: Theme) {

    }
}
