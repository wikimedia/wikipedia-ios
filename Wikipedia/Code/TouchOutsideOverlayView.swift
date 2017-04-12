

protocol TouchOutsideOverlayDelegate: NSObjectProtocol {
    
    func touchOutside(_ overlayView: TouchOutsideOverlayView) -> Void
}

class TouchOutsideOverlayView: UIView {
    
    weak var delegate: TouchOutsideOverlayDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        for subview in self.subviews {
            if (subview.frame.contains(point)) {
                return true
            }
        }
        
        delegate?.touchOutside(self)
        return false
    }
}
