public enum HorizontalAlignment : Int {
    case center
    case left
    case right
}

public enum VerticalAlignment : Int {
    case center
    case top
    case bottom
}

extension UIView {
    public func wmf_preferredFrame(at point: CGPoint, maximumViewSize: CGSize, minimumLayoutAreaSize: CGSize = CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric), horizontalAlignment: HorizontalAlignment, verticalAlignment: VerticalAlignment, apply: Bool) -> CGRect {
        let viewSize = sizeThatFits(maximumViewSize)
        var x = point.x
        var y = point.y
        
        let viewWidth: CGFloat
        if maximumViewSize.width == UIViewNoIntrinsicMetric { // width can be anything
            viewWidth = viewSize.width
        } else {
            viewWidth = min(maximumViewSize.width, viewSize.width)
        }
        
        let viewHeight: CGFloat
        if maximumViewSize.height == UIViewNoIntrinsicMetric { // height can be anything
            viewHeight = viewSize.height
        } else {
            viewHeight = min(maximumViewSize.width, viewSize.height)
        }
        
        let widthToFit: CGFloat
        if minimumLayoutAreaSize.width == UIViewNoIntrinsicMetric { // width can be 0
            widthToFit = maximumViewSize.width
        } else {
            widthToFit = max(minimumLayoutAreaSize.width, viewWidth)
        }
        
        let heightToFit: CGFloat
        if minimumLayoutAreaSize.height == UIViewNoIntrinsicMetric { // height can be 0
            heightToFit = viewHeight
        } else {
            heightToFit = max(minimumLayoutAreaSize.height, viewHeight)
        }
        
        switch verticalAlignment {
        case .center:
            y += floor(0.5*heightToFit - 0.5*viewHeight)
        case .bottom:
            y += (heightToFit - viewHeight)
        case .top:
            break
        }
        
        switch horizontalAlignment {
        case .center:
            x += floor(0.5*widthToFit - 0.5*viewWidth)
        case .right:
            x += (widthToFit - viewWidth)
        case .left:
            break
        }
        
        let fitFrame = CGRect(x: x, y: y, width: viewWidth, height: viewHeight)
        if apply {
            frame = fitFrame
        }
        return fitFrame
    }
    
    @objc public func wmf_preferredFrame(at point: CGPoint, fitting size: CGSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let horizontalAlignment: HorizontalAlignment = semanticContentAttribute == .forceRightToLeft ? .right : .left
        return wmf_preferredFrame(at: point, maximumViewSize: size, minimumLayoutAreaSize: size, horizontalAlignment: horizontalAlignment, verticalAlignment: .top, apply: apply)
    }
    
    @objc(wmf_preferredFrameAtPoint:fittingAvailableWidth:alignedBySemanticContentAttribute:apply:)
    public func wmf_preferredFrame(at point: CGPoint, fitting availableWidth: CGFloat, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        if let imageButton = self as? AlignedImageButton {
            let size = CGSize(width: availableWidth + imageButton.leftPadding + imageButton.rightPadding, height: UIViewNoIntrinsicMetric)
            return self.wmf_preferredFrame(at: CGPoint(x: point.x - imageButton.leftPadding, y: point.y - imageButton.verticalPadding), fitting: size, alignedBy: semanticContentAttribute, apply: apply)
        } else {
            let size = CGSize(width: availableWidth, height: UIViewNoIntrinsicMetric)
            return self.wmf_preferredFrame(at: point, fitting: size, alignedBy: semanticContentAttribute, apply: apply)
        }
        
    }
    
    public func wmf_preferredHeight(at point: CGPoint, fitting availableWidth: CGFloat, alignedBy semanticContentAttribute: UISemanticContentAttribute, spacing: CGFloat, apply: Bool) -> CGFloat {
        return wmf_preferredFrame(at: point, fitting: availableWidth, alignedBy: semanticContentAttribute, apply: apply).layoutHeight(with: spacing)
    }
    
    
}

extension UILabel {
    public override func wmf_preferredFrame(at point: CGPoint, fitting size: CGSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        guard self.wmf_hasText else {
            return .zero
        }
        return super.wmf_preferredFrame(at: point, fitting: size, alignedBy: semanticContentAttribute, apply: apply)
    }
}
