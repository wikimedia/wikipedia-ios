import Foundation
import UIKit


extension UIBezierPath {
    static func CGPointGetMidPointFromPoint(fromPoint: CGPoint, toPoint: CGPoint) -> CGPoint {
        return CGPoint(x: 0.5*(fromPoint.x + toPoint.x), y: 0.5*(fromPoint.y + toPoint.y))
    }
    
    static func CGPointGetQuadCurveControlPointFromPoint(fromPoint: CGPoint, toPoint: CGPoint) -> CGPoint  {
        var controlPoint = CGPointGetMidPointFromPoint(fromPoint, toPoint: toPoint)
        let deltaY = toPoint.y - controlPoint.y
        controlPoint.y += deltaY
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
        
        path.lineJoinStyle = CGLineJoin.Round
        path.lineCapStyle = CGLineCap.Round
        
        return path
    }
}


public class WMFSparklineView : UIView {
    var sparklineLayer = CAShapeLayer()
    var gridlineLayer = CAShapeLayer()
    var gradientLayer = CAGradientLayer()
    let useLogScale = true
    
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
        gridlineLayer.fillColor = UIColor.clearColor().CGColor
        gridlineLayer.strokeColor = UIColor(white: 0.6, alpha: 0.2).CGColor
        gridlineLayer.lineWidth = 1.0
        layer.addSublayer(gridlineLayer)
        
        sparklineLayer.fillColor = UIColor.clearColor().CGColor
        sparklineLayer.lineWidth = 1.5
        sparklineLayer.strokeColor = UIColor.blackColor().CGColor
    
        let startColor = UIColor(red: 51.0/255.0, green:  102.0/255.0, blue: 204.0/255.0, alpha: 1.0).CGColor
        let endColor = UIColor(red: 0.0/255.0, green:  175.0/255.0, blue: 137.0/255.0, alpha: 1.0).CGColor
        gradientLayer.colors = [startColor, endColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.mask = sparklineLayer
        layer.addSublayer(gradientLayer)
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        
        sparklineLayer.frame = layer.bounds
        gridlineLayer.frame = layer.bounds
        gradientLayer.frame = layer.bounds
        
        let margin: CGFloat = 2
        let minX = margin
        let minY = margin
        let maxX = CGRectGetMaxX(layer.bounds) - margin
        let maxY = CGRectGetMaxY(layer.bounds) - margin
        let width = maxX - minX
        let height = maxY - minY
        
        let gridlinePath = UIBezierPath()
        
        let firstGridlineY: CGFloat = minY
        gridlinePath.moveToPoint(CGPoint(x: minX, y: firstGridlineY))
        gridlinePath.addLineToPoint(CGPoint(x: maxX, y:firstGridlineY))
        
        let secondGridlineY = maxY
        gridlinePath.moveToPoint(CGPoint(x: minX, y: secondGridlineY))
        gridlinePath.addLineToPoint(CGPoint(x: maxX, y: secondGridlineY))

        gridlineLayer.path = gridlinePath.CGPath
        
        let delta = maxDataValue - minDataValue
        var x: CGFloat = minX
        let xInterval = width/CGFloat(dataValues.count - 1)
        var points = [CGPoint]()
        for dataValue in dataValues {
            let floatValue = CGFloat(dataValue.doubleValue)
            let relativeY = floatValue - minDataValue
            let normalizedY = 1 - relativeY/delta
            let y = minY + height*normalizedY
            points.append(CGPoint(x: x, y: y))
            x += xInterval
        }
        sparklineLayer.path = UIBezierPath.quadCurvePathWithPoints(points).CGPath
    }

}
