@objc(WMFLongPressButtonDelegate) public protocol LongPressButtonDelegate {
    func longPressButtonDidReceiveLongPress(_ longPressButton: LongPressButton)
}

@objc(WMFLongPressButton) public class LongPressButton: AlignedImageButton {
    var longPressGestureRecognizer: UILongPressGestureRecognizer?
    public weak var longPressDelegate: LongPressButtonDelegate?  {
        didSet {
            if let lpgr = longPressGestureRecognizer, longPressDelegate == nil {
                removeGestureRecognizer(lpgr)
            } else if longPressDelegate != nil && longPressGestureRecognizer == nil {
                let lpgr = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGestureRecognizer(_:)))
                addGestureRecognizer(lpgr)
                longPressGestureRecognizer = lpgr
            }
        }
    }
    
    @objc public func handleLongPressGestureRecognizer(_ longPressGestureRecognizer: UILongPressGestureRecognizer) {
        guard longPressGestureRecognizer.state == .began else {
            return
        }
        longPressDelegate?.longPressButtonDidReceiveLongPress(self)
    }
}
