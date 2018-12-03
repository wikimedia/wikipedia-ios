@objc(WMFContextualHighlightEditToolbarAccessoryView)
class ContextualHighlightEditToolbarAccessoryView: UIView {
    @IBOutlet var separatorViews: [UIView] = []

    // MARK: Initialization

    @objc static func loadFromNib() -> ContextualHighlightEditToolbarAccessoryView {
        let nib = UINib(nibName: "ContextualHighlightEditToolbarAccessoryView", bundle: Bundle.main)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! ContextualHighlightEditToolbarAccessoryView
        return view
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
