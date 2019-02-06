class EditToolbarView: UIView, TextFormattingButtonsProviding {
    weak var delegate: TextFormattingDelegate?
    
    @IBOutlet var separatorViews: [UIView] = []
    @IBOutlet var buttons: [TextFormattingButton] = []

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height + 1)
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
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
        for button in buttons {
            button.apply(theme: theme)
        }
    }
}
