import UIKit

class OnThisDayTimelineView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
        backgroundColor = .clear
    }

    public var shouldAnimateDots: Bool = false
    
    public var pauseDotsAnimation: Bool = true {
        didSet {
            displayLink?.isPaused = pauseDotsAnimation
        }
    }

    let dotRadius:CGFloat = 9.0
    let dotMinRadiusNormal:CGFloat = 0.4
    
    public var topDotsY: CGFloat = 0 {
        didSet {
            guard shouldAnimateDots == false else {
                return
            }
            updateTopDotsRadii(to: 1.0, at: CGPoint(x: frame.midX, y: topDotsY))
        }
    }

    public var bottomDotY: CGFloat = 0 {
        didSet {
            guard shouldAnimateDots == false else {
                return
            }
            bottomDotShapeLayer.updateDotRadius(dotRadius * dotMinRadiusNormal, center: CGPoint(x: frame.midX, y: bottomDotY))
        }
    }

    private lazy var bottomDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.strokeColor = UIColor.wmf_blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    lazy var outerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.strokeColor = UIColor.wmf_blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    lazy var innerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.wmf_blue.cgColor
        shape.strokeColor = UIColor.wmf_blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    private lazy var displayLink: CADisplayLink? = {
        guard self.shouldAnimateDots == true else {
            return nil
        }
        let link = CADisplayLink(target: self, selector: #selector(maybeUpdateTopDotsRadii))
        link.add(to: RunLoop.main, forMode: RunLoopMode.commonModes)
        return link
    }()
    
    override func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        super.removeFromSuperview()
    }

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        drawVerticalLine(in: context, rect: rect)
    }
    
    private func drawVerticalLine(in context: CGContext, rect: CGRect){
        context.setLineWidth(1.0)
        context.setStrokeColor(UIColor.wmf_blue.cgColor)
        context.move(to: CGPoint(x: rect.midX, y: rect.minY))
        context.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        context.strokePath()
    }
    
    // Returns CGFloat in range from 0.0 to 1.0. 0.0 indicates dot should be minimized.
    // 1.0 indicates dot should be maximized. Approaches 1.0 as timelineView.dotY
    // approaches vertical center. Approaches 0.0 as timelineView.dotY approaches top
    // or bottom.
    private func dotRadiusNormal(with y:CGFloat, in container:UIView) -> CGFloat {
        let yInContainer = convert(CGPoint(x:0, y:y), to: container).y
        let halfContainerHeight = container.bounds.size.height * 0.5
        return max(0.0, 1.0 - (abs(yInContainer - halfContainerHeight) / halfContainerHeight))
    }

    private var lastDotRadiusNormal: CGFloat = -1.0 // -1.0 so dots with dotAnimationNormal of "0.0" are visible initially
    
    @objc private func maybeUpdateTopDotsRadii() {
        guard let containerView = window else {
            return
        }

        // Shift the "full-width dot" point up a bit - otherwise it's in the vertical center of screen.
        let yOffset = containerView.bounds.size.height * 0.15

        var radiusNormal = dotRadiusNormal(with: topDotsY + yOffset, in: containerView)

        // Reminder: can reduce precision to 1 (significant digit) to reduce how often dot radii are updated.
        let precision: CGFloat = 2
        let roundingNumber = pow(10, precision)
        radiusNormal = (radiusNormal * roundingNumber).rounded(.up) / roundingNumber
        
        guard radiusNormal != lastDotRadiusNormal else {
            return
        }
        
        updateTopDotsRadii(to: radiusNormal, at: CGPoint(x: frame.midX, y: topDotsY))
        
        lastDotRadiusNormal = radiusNormal
    }
    
    private func updateTopDotsRadii(to radiusNormal: CGFloat, at center: CGPoint){
        outerDotShapeLayer.updateDotRadius(dotRadius * max(radiusNormal, dotMinRadiusNormal), center: center)
        innerDotShapeLayer.updateDotRadius(dotRadius * max((radiusNormal - dotMinRadiusNormal), 0.0), center: center)
    }
}

extension CAShapeLayer {
    fileprivate func updateDotRadius(_ radius: CGFloat, center: CGPoint) {
        path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle:CGFloat.pi * 2.0, clockwise: true).cgPath
    }
}
