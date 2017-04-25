

protocol TouchOutsideOverlayDelegate: NSObjectProtocol {
    
    func touchOutside(_ overlayView: TouchOutsideOverlayView) -> Void
}

class TouchOutsideOverlayView: UIView {
    
    weak var delegate: TouchOutsideOverlayDelegate?
    
    private var rects: [CGRect] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        
        for r in rects {
            if r.contains(point) {
                return false
            }
        }
        
        delegate?.touchOutside(self)
        return false
    }
    
    func addInsideRect(fromView view: UIView) {
        guard let superview = view.superview else {
            // TODO: error
            return
        }
        
        rects.append(self.convert(view.frame, from: superview))
    }
    
    func resetInsideRects() {
        rects = []
    }
}
