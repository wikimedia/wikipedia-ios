class TextFormattingButton: UIButton, Themeable {
    var theme: Theme = Theme.standard
    
    override var isSelected: Bool {
        didSet{
            updateColors()
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        clipsToBounds = true
    }

    override open var intrinsicContentSize: CGSize {
        get {
            // Increase touch targets & make widths more consistent
            let superSize = super.intrinsicContentSize
            return CGSize(width: max(superSize.width, 35), height: max(superSize.height, 35))
        }
    }
    
    private func updateColors() {
        self.tintColor = self.isSelected ? theme.colors.secondaryText : theme.colors.primaryText
        self.backgroundColor = self.isSelected ? theme.colors.baseBackground : .clear
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        updateColors()
    }
}
