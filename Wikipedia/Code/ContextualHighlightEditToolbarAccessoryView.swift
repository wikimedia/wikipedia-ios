@objc(WMFContextualHighlightEditToolbarAccessoryView)
class ContextualHighlightEditToolbarAccessoryView: EditToolbarAccessoryView {

    // MARK: Initialization

    @objc static func loadFromNib() -> ContextualHighlightEditToolbarAccessoryView {
        let nib = UINib(nibName: "ContextualHighlightEditToolbarAccessoryView", bundle: Bundle.main)
        let view = nib.instantiate(withOwner: nil, options: nil).first as! ContextualHighlightEditToolbarAccessoryView
        return view
    }
}
