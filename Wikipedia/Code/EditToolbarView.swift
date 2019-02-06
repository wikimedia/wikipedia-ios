class EditToolbarView: UIView, TextFormattingButtonsProviding {
    weak var delegate: TextFormattingDelegate?
    
    @IBOutlet var separatorViews: [UIView] = []
    @IBOutlet var buttons: [TextFormattingButton] = []

    override var intrinsicContentSize: CGSize {
        let height = buttons.map { $0.intrinsicContentSize.height }.max() ?? UIView.noIntrinsicMetric
        return CGSize(width: UIView.noIntrinsicMetric, height: height)
    }
}

extension EditToolbarView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.inputAccessoryBackground
        tintColor = theme.colors.link
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
        for button in buttons {
            button.apply(theme: theme)
        }
    }
}
