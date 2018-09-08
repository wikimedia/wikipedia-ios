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
    public var minimizeUnanimatedDots: Bool = false
    
    public var pauseDotsAnimation: Bool = true {
        didSet {
            displayLink?.isPaused = pauseDotsAnimation
        }
    }

    private let dotRadius:CGFloat = 9.0
    private let dotMinRadiusNormal:CGFloat = 0.4
    
    public var dotsY: CGFloat = 0 {
        didSet {
            guard shouldAnimateDots == false else {
                return
            }
            updateDotsRadii(to: minimizeUnanimatedDots ? 0.0 : 1.0, at: CGPoint(x: bounds.midX, y: dotsY))
        }
    }
    
    override public func tintColorDidChange() {
        super.tintColorDidChange()
        outerDotShapeLayer.strokeColor = tintColor.cgColor
        innerDotShapeLayer.fillColor = tintColor.cgColor
        innerDotShapeLayer.strokeColor = tintColor.cgColor
        setNeedsDisplay()
    }
    
    override public var backgroundColor: UIColor? {
        didSet {
            outerDotShapeLayer.fillColor = backgroundColor?.cgColor
        }
    }

    private lazy var outerDotShapeLayer: CAShapeLayer = {
        let shape = CAShapeLayer()
        shape.fillColor = UIColor.white.cgColor
        shape.strokeColor = UIColor.blue.cgColor
        shape.lineWidth = 1.0
        self.layer.addSublayer(shape)
        return shape
    }()

    private lazy var innerDotShapeLayer: CAShapeLayer = {
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
        let link = CADisplayLink(target: self, selector: #selector(maybeUpdateDotsRadii))
        link.add(to: RunLoop.main, forMode: RunLoop.Mode.common)
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
    
    public var extendTimelineAboveDot: Bool = true {
        didSet {
            if oldValue != extendTimelineAboveDot {
                setNeedsDisplay()
            }
        }
    }
    
    private func drawVerticalLine(in context: CGContext, rect: CGRect){
        context.setLineWidth(1.0)
        context.setStrokeColor(tintColor.cgColor)
        let lineTopY = extendTimelineAboveDot ? rect.minY : dotsY
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
    
    @objc private func maybeUpdateDotsRadii() {
        guard let containerView = window else {
            return
        }

        // Shift the "full-width dot" point up a bit - otherwise it's in the vertical center of screen.
        let yOffset = containerView.bounds.size.height * 0.15

        var radiusNormal = dotRadiusNormal(with: dotsY + yOffset, in: containerView)

        // Reminder: can reduce precision to 1 (significant digit) to reduce how often dot radii are updated.
        let precision: CGFloat = 2
        let roundingNumber = pow(10, precision)
        radiusNormal = (radiusNormal * roundingNumber).rounded(.up) / roundingNumber
        
        guard radiusNormal != lastDotRadiusNormal else {
            return
        }
        
        updateDotsRadii(to: radiusNormal, at: CGPoint(x: bounds.midX, y: dotsY))
        
        // Progressively fade the inner dot when it gets tiny.
        innerDotShapeLayer.opacity = easeInOutQuart(number: Float(radiusNormal))
        
        lastDotRadiusNormal = radiusNormal
    }
    
    private func updateDotsRadii(to radiusNormal: CGFloat, at center: CGPoint){
        outerDotShapeLayer.updateDotRadius(dotRadius * max(radiusNormal, dotMinRadiusNormal), center: center)
        innerDotShapeLayer.updateDotRadius(dotRadius * max((radiusNormal - dotMinRadiusNormal), 0.0), center: center)
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
