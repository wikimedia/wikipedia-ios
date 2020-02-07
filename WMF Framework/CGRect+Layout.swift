extension CGRect {
    // Height required to layout this rect. Returns 0 if rect.height is 0. Returns height plus spacing otherwise.
    public func layoutHeight(with spacing: CGFloat) -> CGFloat {
        return height > 0 ? height + spacing : 0
    }
    
    public var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
}
