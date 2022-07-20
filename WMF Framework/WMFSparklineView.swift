import Foundation
import UIKit


extension UIBezierPath {
    static func CGPointGetMidPointFromPoint(_ fromPoint: CGPoint, toPoint: CGPoint) -> CGPoint {
        return CGPoint(x: 0.5*(fromPoint.x + toPoint.x), y: 0.5*(fromPoint.y + toPoint.y))
    }
    
    static func CGPointGetQuadCurveControlPointFromPoint(_ fromPoint: CGPoint, toPoint: CGPoint) -> CGPoint {
        var controlPoint = CGPointGetMidPointFromPoint(fromPoint, toPoint: toPoint)
        let deltaY = toPoint.y - controlPoint.y
        controlPoint.y += deltaY
        return controlPoint
    }
    
    class func quadCurvePathWithPoints(_ points: [CGPoint]) -> UIBezierPath {
        let path = UIBezierPath()
        
        guard points.count > 1 else {
            return path
        }
        
        path.move(to: points[0])
        
        guard points.count > 2 else {
            path.addLine(to: points[1])
            return path
        }
        
        var i = 0
        for toPoint in points[1...(points.count - 1)] {
            let fromPoint = points[i]
            let midPoint = CGPointGetMidPointFromPoint(fromPoint, toPoint: toPoint)
            let midPointControlPoint = CGPointGetQuadCurveControlPointFromPoint(midPoint, toPoint: fromPoint)
            path.addQuadCurve(to: midPoint, controlPoint: midPointControlPoint)
            let toPointControlPoint = CGPointGetQuadCurveControlPointFromPoint(midPoint, toPoint: toPoint)
            path.addQuadCurve(to: toPoint, controlPoint: toPointControlPoint)
            i += 1
        }
        
        path.lineJoinStyle = CGLineJoin.round
        path.lineCapStyle = CGLineCap.round
        
        return path
    }
}


open class WMFSparklineView : UIView, Themeable {
    var sparklineLayer = CAShapeLayer()
    var gridlineLayer = CAShapeLayer()
    var gradientLayer = CAGradientLayer()
    let useLogScale = true
    
    public func apply(theme: Theme) {
        gridlineLayer.strokeColor = theme.colors.border.cgColor
        gradientLayer.colors = [theme.colors.rankGradientStart.cgColor, theme.colors.rankGradientEnd.cgColor]
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    open var maxDataValue: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var minDataValue: CGFloat = 0 {
        didSet {
            setNeedsLayout()
        }
    }
    
    open var dataValues: [NSNumber] = [] {
        didSet {
            setNeedsLayout()
            updateMinAndMaxFromDataValues()
        }
    }
    
    open var showsVerticalGridlines = false {
        didSet {
            setNeedsLayout()
        }
    }
    
    @IBInspectable open var gridlineWidth: CGFloat = 0.5 {
        didSet {
            gridlineLayer.lineWidth = gridlineWidth
        }
    }
    
    @IBInspectable open var sparklineWidth: CGFloat = 1.0 {
        didSet {
            sparklineLayer.lineWidth = sparklineWidth
        }
    }
    
    open func updateMinAndMaxFromDataValues() {
        var min = CGFloat.greatestFiniteMagnitude
        var max = CGFloat.leastNormalMagnitude
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
        apply(theme: Theme.standard)

        gridlineLayer.fillColor = UIColor.clear.cgColor
        gridlineWidth = 0.5
        layer.addSublayer(gridlineLayer)
        
        sparklineLayer.fillColor = UIColor.clear.cgColor
        sparklineWidth = 1.5
        sparklineLayer.strokeColor = UIColor.black.cgColor
    
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.mask = sparklineLayer
        layer.addSublayer(gradientLayer)
        
    }
    
    override open func layoutSubviews() {
        super.layoutSubviews()
        
        sparklineLayer.frame = layer.bounds
        gridlineLayer.frame = layer.bounds
        gradientLayer.frame = layer.bounds
        
        let margin: CGFloat = 2
        let minX = margin
        let minY = margin
        let maxX = layer.bounds.maxX - margin
        let maxY = layer.bounds.maxY - margin
        let width = maxX - minX
        let height = maxY - minY
        
        let gridlinePath = UIBezierPath()
        
        let firstGridlineY: CGFloat = minY
        gridlinePath.move(to: CGPoint(x: minX, y: firstGridlineY))
        gridlinePath.addLine(to: CGPoint(x: maxX, y:firstGridlineY))
        
        let secondGridlineY = maxY
        gridlinePath.move(to: CGPoint(x: minX, y: secondGridlineY))
        gridlinePath.addLine(to: CGPoint(x: maxX, y: secondGridlineY))
        
        if showsVerticalGridlines {
            let lowerGridlineY = 0.33*(firstGridlineY + secondGridlineY)
            gridlinePath.move(to: CGPoint(x: minX, y: lowerGridlineY))
            gridlinePath.addLine(to: CGPoint(x: maxX, y: lowerGridlineY))
            
            let higherGridlineY = 0.67*(firstGridlineY + secondGridlineY)
            gridlinePath.move(to: CGPoint(x: minX, y: higherGridlineY))
            gridlinePath.addLine(to: CGPoint(x: maxX, y: higherGridlineY))
        }
        
        let delta = maxDataValue - minDataValue
        let lastIndex = dataValues.count - 1
        let xInterval = width/CGFloat(lastIndex)
        var points = [CGPoint]()
        for (i, dataValue) in dataValues.enumerated() {
            let floatValue = CGFloat(dataValue.doubleValue)
            let relativeY = floatValue - minDataValue
            let normalizedY = 1 - relativeY/delta
            let y = minY + height*normalizedY
            let x = xInterval * CGFloat(i)
            points.append(CGPoint(x: x, y: y))
            if showsVerticalGridlines && i != 0 && i != lastIndex {
                gridlinePath.move(to: CGPoint(x: x, y: minY - 5))
                gridlinePath.addLine(to: CGPoint(x: x, y: maxY + 5))
            }
        }
        gridlineLayer.path = gridlinePath.cgPath

        sparklineLayer.path = UIBezierPath.quadCurvePathWithPoints(points).cgPath
    }

}
