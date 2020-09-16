import CoreGraphics

/// Adapted from WMFSparklineView.swift
extension CGPoint {
    
    static func midPointFrom(_ fromPoint: CGPoint, to toPoint: CGPoint) -> CGPoint {
        return CGPoint(x: 0.5*(fromPoint.x + toPoint.x), y: 0.5*(fromPoint.y + toPoint.y))
    }
    
    static func quadCurveControlPointFrom(_ fromPoint: CGPoint, to toPoint: CGPoint) -> CGPoint {
        var controlPoint = midPointFrom(fromPoint, to: toPoint)
        let deltaY = toPoint.y - controlPoint.y
        controlPoint.y += deltaY
        return controlPoint
    }
    
}
