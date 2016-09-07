import Foundation
import UIKit


extension UIBezierPath {
    static func CGPointGetMidPointFromPoint(fromPoint: CGPoint, toPoint: CGPoint) -> CGPoint {
        return CGPoint(x: 0.5*(fromPoint.x + toPoint.x), y: 0.5*(fromPoint.y + toPoint.y))
    }
    
    static func CGPointGetQuadCurveControlPointFromPoint(fromPoint: CGPoint, toPoint: CGPoint) -> CGPoint  {
        var controlPoint = CGPointGetMidPointFromPoint(fromPoint, toPoint: toPoint)
        let diffY = abs(toPoint.y - controlPoint.y);
        
        if fromPoint.y < toPoint.y {
            controlPoint.y += diffY
        } else if fromPoint.y > toPoint.y {
            controlPoint.y -= diffY
        }
        
        return controlPoint
    }
    
    class func quadCurvePathWithPoints(points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        
        guard points.count > 1 else {
            return path
        }
        
        path.moveToPoint(points[0])
        
        guard points.count > 2 else {
            path.addLineToPoint(points[1])
            return path
        }
        
        var i = 0
        for toPoint in points[1...(points.count - 1)] {
            let fromPoint = points[i]
            let midPoint = CGPointGetMidPointFromPoint(fromPoint, toPoint: toPoint)
            let midPointControlPoint = CGPointGetQuadCurveControlPointFromPoint(midPoint, toPoint: fromPoint)
            path.addQuadCurveToPoint(midPoint, controlPoint: midPointControlPoint)
            let toPointControlPoint = CGPointGetQuadCurveControlPointFromPoint(midPoint, toPoint: toPoint)
            path.addQuadCurveToPoint(toPoint, controlPoint: toPointControlPoint)
            i += 1
        }
        
        return path
    }
}


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
        let gridlinePath = UIBezierPath()
        
        let firstGridlineY: CGFloat = 0
        gridlinePath.moveToPoint(CGPoint(x: 0, y: firstGridlineY))
        gridlinePath.addLineToPoint(CGPoint(x: maxX, y:firstGridlineY))
        
        let secondGridlineY = maxY
        gridlinePath.moveToPoint(CGPoint(x: 0, y: secondGridlineY))
        gridlinePath.addLineToPoint(CGPoint(x: maxX, y: secondGridlineY))

        gridlineLayer.path = gridlinePath.CGPath
        
        let sparklinePath = UIBezierPath()
        sparklinePath.lineJoinStyle = CGLineJoin.Round
        let delta = maxDataValue - minDataValue
        var x: CGFloat = 0
        let xInterval = maxX/CGFloat(dataValues.count - 1)
        var points = [CGPoint]()
        for dataValue in dataValues {
            let floatValue = CGFloat(dataValue.doubleValue)
            let relativeY = (floatValue - minDataValue)/delta
            let y = maxY*(1 - relativeY)
            points.append(CGPoint(x: x, y: y))
            x += xInterval
        }
        sparklineLayer.path = UIBezierPath.quadCurvePathWithPoints(points).CGPath
    }

}
