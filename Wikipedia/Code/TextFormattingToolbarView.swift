class TextFormattingToolbarView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    @IBOutlet var allButtons: [TextFormattingButton]!
    @IBOutlet weak var boldButton: TextFormattingButton!
    @IBOutlet weak var italicButton: TextFormattingButton!
    @IBOutlet weak var citationButton: TextFormattingButton!
    @IBOutlet weak var templateButton: TextFormattingButton!
    @IBOutlet weak var exclamationButton: TextFormattingButton!
    @IBOutlet weak var linkButton: TextFormattingButton!

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
