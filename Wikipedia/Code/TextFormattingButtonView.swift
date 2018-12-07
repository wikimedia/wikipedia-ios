class TextFormattingButtonView: UIView, TextFormattingProviding {
    weak var delegate: TextFormattingDelegate?

    @IBOutlet private weak var button: UIButton!

    var buttonTitle: String? {
        didSet {
            button.setTitle(buttonTitle, for: .normal)
        }
    }

    var buttonTitleColor: UIColor? {
        didSet {
            button.setTitleColor(buttonTitleColor, for: .normal)
        }
    }
}

extension TextFormattingButtonView: Themeable {
    func apply(theme: Theme) {
        button.setTitleColor(buttonTitleColor, for: .normal)
    }
}
