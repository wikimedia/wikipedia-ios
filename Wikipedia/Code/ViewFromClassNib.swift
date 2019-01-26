
class ViewFromClassNib: UIView {
    override func awakeAfter(using aDecoder: NSCoder) -> Any? {
        guard subviews.count == 0, let viewFromNib = type(of:self).wmf_viewFromClassNib() else {
            return self
        }
        return viewFromNib
    }
}
