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
    
    public var showsVerticalGridlines = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable public var gridlineWidth: CGFloat = 0.5 {
        didSet {
            gridlineLayer.lineWidth = gridlineWidth
        }
    }
    
    @IBInspectable public var sparklineWidth: CGFloat = 1.0 {
        didSet {
            sparklineLayer.lineWidth = sparklineWidth
        }
    }
    
    public func updateMinAndMaxFromDataValues() {
        var min = CGFloat.max
        var max = CGFloat.min
        for val in dataValues {
            let val = CGFloat(val.doubleValue)
            if val < min {
                min = val
            }
            if val > max {
                max = val
            }
        }
        minDataValue = min
        maxDataValue = max
    }
    
    func setup() {
        gridlineLayer.fillColor = UIColor.clearColor().CGColor
        gridlineWidth = 0.5
        gridlineLayer.strokeColor = UIColor(white: 0.6, alpha: 0.2).CGColor
        layer.addSublayer(gridlineLayer)
        
        sparklineLayer.fillColor = UIColor.clearColor().CGColor
        sparklineWidth = 1.5
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
        
        if showsVerticalGridlines {
            let lowerGridlineY = 0.33*(firstGridlineY + secondGridlineY)
            gridlinePath.moveToPoint(CGPoint(x: minX, y: lowerGridlineY))
            gridlinePath.addLineToPoint(CGPoint(x: maxX, y: lowerGridlineY))
            
            let higherGridlineY = 0.67*(firstGridlineY + secondGridlineY)
            gridlinePath.moveToPoint(CGPoint(x: minX, y: higherGridlineY))
            gridlinePath.addLineToPoint(CGPoint(x: maxX, y: higherGridlineY))
        }
        
        let delta = maxDataValue - minDataValue
        let lastIndex = dataValues.count - 1
        let xInterval = width/CGFloat(lastIndex)
        var points = [CGPoint]()
        for (i, dataValue) in dataValues.enumerate() {
            let floatValue = CGFloat(dataValue.doubleValue)
            let relativeY = floatValue - minDataValue
            let normalizedY = 1 - relativeY/delta
            let y = minY + height*normalizedY
            let x = xInterval * CGFloat(i)
            points.append(CGPoint(x: x, y: y))
            if showsVerticalGridlines && i != 0 && i != lastIndex {
                gridlinePath.moveToPoint(CGPoint(x: x, y: minY - 5))
                gridlinePath.addLineToPoint(CGPoint(x: x, y: maxY + 5))
            }
        }
        gridlineLayer.path = gridlinePath.CGPath

        sparklineLayer.path = UIBezierPath.quadCurvePathWithPoints(points).CGPath
    }

}
