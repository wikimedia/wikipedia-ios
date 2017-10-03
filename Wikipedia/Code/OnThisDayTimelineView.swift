import UIKit

public class OnThisDayTimelineView: UIView {
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open func setup() {
    }

    public var shouldAnimateDots: Bool = false
    
    public var pauseDotsAnimation: Bool = true {
        didSet {
            displayLink?.isPaused = pauseDotsAnimation
        }
    }

    private let dotRadius:CGFloat = 9.0
    private let dotMinRadiusNormal:CGFloat = 0.4
    
    public var topDotsY: CGFloat = 0 {
        didSet {
            guard shouldAnimateDots == false else {
                return
            }
            updateTopDotsRadii(to: 1.0, at: CGPoint(x: bounds.midX, y: topDotsY))
        }
    }

    public var bottomDotY: CGFloat = 0 {
        didSet {
            guard shouldAnimateDots == false else {
                return
            }
            bottomDotShapeLayer.updateDotRadius(dotRadius * dotMinRadiusNormal, center: CGPoint(x: bounds.midX, y: bottomDotY))
        }
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        bottomDotShapeLayer.strokeColor = tintColor.cgColor
        topOuterDotShapeLayer.strokeColor = tintColor.cgColor
        topInnerDotShapeLayer.fillColor = tintColor.cgColor
        topInnerDotShapeLayer.strokeColor = tintColor.cgColor
        setNeedsDisplay()
    }
    
    override public var backgroundColor: UIColor? {
        didSet {
            bottomDotShapeLayer.fillColor = backgroundColor?.cgColor
            topOuterDotShapeLayer.fillColor = backgroundColor?.cgColor
        }
    }

    private lazy var bottomDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.strokeColor = UIColor.blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    private lazy var topOuterDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.strokeColor = UIColor.blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    private lazy var topInnerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.blue.cgColor
        shape.strokeColor = UIColor.blue.cgColor
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
    
    override public func removeFromSuperview() {
        displayLink?.invalidate()
        displayLink = nil
        super.removeFromSuperview()
    }

    override public func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else {
            return
        }
        drawVerticalLine(in: context, rect: rect)
    }
    
    public var extendTimelineAboveTopDot: Bool = true {
        didSet {
            if oldValue != extendTimelineAboveTopDot {
                setNeedsDisplay()
            }
        }
    }
    
    private func drawVerticalLine(in context: CGContext, rect: CGRect){
        context.setLineWidth(1.0)
        context.setStrokeColor(tintColor.cgColor)
        let lineTopY = extendTimelineAboveTopDot ? rect.minY : topDotsY
        context.move(to: CGPoint(x: rect.midX, y: lineTopY))
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
        
        updateTopDotsRadii(to: radiusNormal, at: CGPoint(x: bounds.midX, y: topDotsY))
        
        // Progressively fade the inner dot when it gets tiny.
        topInnerDotShapeLayer.opacity = easeInOutQuart(number: Float(radiusNormal))
        
        lastDotRadiusNormal = radiusNormal
    }
    
    private func updateTopDotsRadii(to radiusNormal: CGFloat, at center: CGPoint){
        topOuterDotShapeLayer.updateDotRadius(dotRadius * max(radiusNormal, dotMinRadiusNormal), center: center)
        topInnerDotShapeLayer.updateDotRadius(dotRadius * max((radiusNormal - dotMinRadiusNormal), 0.0), center: center)
    }
    
    private func easeInOutQuart(number:Float) -> Float {
        return number < 0.5 ? 8.0 * pow(number, 4) : 1.0 - 8.0 * (number - 1.0) * pow(number, 3)
    }
}

extension CAShapeLayer {
    fileprivate func updateDotRadius(_ radius: CGFloat, center: CGPoint) {
        path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0.0, endAngle:CGFloat.pi * 2.0, clockwise: true).cgPath
    }
}
