class EditToolbarView: UIView {
    @IBOutlet var separatorViews: [UIView] = []
    @IBOutlet var buttons: [UIButton] = []

    override func awakeFromNib() {
        super.awakeFromNib()
        addTopShadow()
        NotificationCenter.default.addObserver(self, selector: #selector(textSelectionDidChange(_:)), name: Notification.Name.WMFSectionEditorSelectionChangedNotification, object: nil)
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

    // MARK: Notifications

    @objc private func textSelectionDidChange(_ notification: Notification) {
        buttons.forEach { $0.isSelected = false }
    }
}

extension EditToolbarView: Themeable {
    func apply(theme: Theme) {
        backgroundColor = theme.colors.midBackground
        layer.shadowColor = theme.colors.shadow.cgColor
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
    }
}
