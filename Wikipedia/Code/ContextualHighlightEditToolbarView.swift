protocol ContextualHighlightEditToolbarViewDelegate: class {
    func contextualHighlightEditToolbarViewDidTapTextFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
    func contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(_ contextualHighlightEditToolbarView: ContextualHighlightEditToolbarView, button: UIButton)
}

class ContextualHighlightEditToolbarView: EditToolbarView {
    weak var delegate: ContextualHighlightEditToolbarViewDelegate?

    @IBAction private func formatHeader(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapHeaderFormattingButton(self, button: sender)
    }

    @IBAction private func formatText(_ sender: UIButton) {
        delegate?.contextualHighlightEditToolbarViewDidTapTextFormattingButton(self, button: sender)
    }
}
