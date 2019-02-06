class TextFormattingButton: UIButton, Themeable {
    var theme: Theme = Theme.standard
    var kind: SectionEditorButton.Kind?
    
    override var isSelected: Bool {
        didSet{
            updateColors()
            if isSelected {
                accessibilityLabel = kind?.removeTitle
            } else {
                accessibilityLabel = kind?.title
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        layer.cornerRadius = 4
        clipsToBounds = true
        kind = SectionEditorButton.Kind(identifier: tag)
        accessibilityLabel = kind?.title
    }

    override open var intrinsicContentSize: CGSize {
        get {
            // Increase touch targets & make widths more consistent
            let superSize = super.intrinsicContentSize
            return CGSize(width: max(superSize.width, 36), height: max(superSize.height, 36))
        }
    }
    
    private func updateColors() {
        self.tintColor = self.isSelected ? theme.colors.inputAccessoryButtonSelectedTint : theme.colors.inputAccessoryButtonTint
        self.backgroundColor = self.isSelected ? theme.colors.inputAccessoryButtonSelectedBackgroundColor : .clear
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        updateColors()
    }
}
