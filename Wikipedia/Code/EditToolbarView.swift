class EditToolbarView: UIView, TextFormattingButtonsProviding {
    weak var delegate: TextFormattingDelegate?
    
    @IBOutlet var separatorViews: [UIView] = []
    @IBOutlet var buttons: [TextFormattingButton] = []

    override var intrinsicContentSize: CGSize {
        let height = buttons.map { $0.intrinsicContentSize.height }.max() ?? UIView.noIntrinsicMetric
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        accessibilityElements = buttons
    }
}

extension EditToolbarView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.inputAccessoryBackground
        tintColor = theme.colors.link
        if theme.hasInputAccessoryShadow {
            layer.shadowOffset = CGSize(width: 0, height: -2)
            layer.shadowRadius = 10
            layer.shadowOpacity = 1.0
            layer.shadowColor = theme.colors.shadow.cgColor
        } else {
            layer.shadowOffset = .zero
            layer.shadowRadius = 0
            layer.shadowOpacity = 0
            layer.shadowColor = nil
        }
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
        for button in buttons {
            button.apply(theme: theme)
        }
    }
}
