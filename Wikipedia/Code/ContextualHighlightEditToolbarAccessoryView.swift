@objc(WMFContextualHighlightEditToolbarAccessoryView)
class ContextualHighlightEditToolbarAccessoryView: EditToolbarAccessoryView {
    @IBOutlet var separatorViews: [UIView] = []

    // MARK: Initialization

    @objc static func loadFromNib() -> ContextualHighlightEditToolbarAccessoryView {
        let nib = UINib(nibName: "ContextualHighlightEditToolbarAccessoryView", bundle: Bundle.main)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! ContextualHighlightEditToolbarAccessoryView
        return view
    }

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

extension ContextualHighlightEditToolbarAccessoryView: Themeable {
    func apply(theme: Theme) {
        separatorViews.forEach { $0.backgroundColor = theme.colors.border }
    }
}
