import Foundation


public class WMFSparklineView : UIView {
    var sparklineLayer = CAShapeLayer()
    var gridlineLayer = CAShapeLayer()

    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    public var maxDataValue: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var minDataValue: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    public var dataValues: [NSNumber] = [] {
        didSet {
            setNeedsLayout()
        }
    }
    
    func setup() {
        gridlineLayer.fillColor = nil
        gridlineLayer.strokeColor = UIColor.grayColor().CGColor
        gridlineLayer.lineWidth = 1.0
        layer.addSublayer(gridlineLayer)
        
        sparklineLayer.fillColor = nil
        sparklineLayer.lineWidth = 2.0
        sparklineLayer.strokeColor = self.tintColor.CGColor
        layer.addSublayer(sparklineLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        sparklineLayer.frame = layer.bounds
        gridlineLayer.frame = layer.bounds
        
        let maxX = CGRectGetMaxX(layer.bounds)
        let maxY = CGRectGetMaxY(layer.bounds)
        let fakeGridLinePercentage: CGFloat = 0.10
        let gridlinePath = UIBezierPath()
        
        let firstGridlineY = fakeGridLinePercentage*maxY
        gridlinePath.moveToPoint(CGPoint(x: 0, y: firstGridlineY))
        gridlinePath.addLineToPoint(CGPoint(x: maxX, y:firstGridlineY))
        
        let secondGridlineY = maxY*(1 - fakeGridLinePercentage)
        gridlinePath.moveToPoint(CGPoint(x: 0, y: secondGridlineY))
        gridlinePath.addLineToPoint(CGPoint(x: maxX, y: secondGridlineY))

        gridlineLayer.path = gridlinePath.CGPath
        
        let sparklinePath = UIBezierPath()
        sparklinePath.lineJoinStyle = CGLineJoin.Round
        let delta = maxDataValue - minDataValue
        var x: CGFloat = 0
        let xInterval = maxX/CGFloat(dataValues.count - 1)
        for dataValue in dataValues {
            let floatValue = CGFloat(dataValue.doubleValue)
            let relativeY = (floatValue - minDataValue)/delta
            let y = maxY*(1 - relativeY)
            if x == 0 {
                sparklinePath.moveToPoint(CGPointMake(x, y))
            } else {
                sparklinePath.addLineToPoint(CGPointMake(x, y))
            }
            x += xInterval
        }
        sparklineLayer.path = sparklinePath.CGPath
    }

}
