class EditToolbarView: UIView {
    @IBOutlet var separatorViews: [UIView] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        addTopShadow()
    }

    private func addTopShadow() {
        layer.shadowOffset = CGSize(width: 0, height: -2)
        layer.shadowRadius = 10
        layer.shadowOpacity = 1.0
    }

    // MARK: Size

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: bounds.height + 1)
    }
}

extension EditToolbarView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.midBackground
        layer.shadowColor = theme.colors.shadow.cgColor
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
    }
}
