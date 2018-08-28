@objc public enum HorizontalAlignment : Int {
    case center
    case left
    case right
}

@objc public enum VerticalAlignment: Int {
    case center
    case top
    case bottom
}

public let NoIntrinsicSize = CGSize(width: UIViewNoIntrinsicMetric, height: UIViewNoIntrinsicMetric)

extension UIView {
    @objc public func wmf_sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size)
    }
    
    @objc public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize = NoIntrinsicSize, minimumSize: CGSize = NoIntrinsicSize, horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: VerticalAlignment = .center, apply: Bool = false) -> CGRect {
        let viewSize: CGSize = wmf_sizeThatFits(maximumSize)
       
        var x: CGFloat = point.x
        var y: CGFloat = point.y
        
        let viewWidth: CGFloat
        let widthToFit: CGFloat

        if minimumSize.width != UIViewNoIntrinsicMetric && maximumSize.width != UIViewNoIntrinsicMetric { // max and min defined
            viewWidth = max(min(maximumSize.width, viewSize.width), minimumSize.width)
            widthToFit = maximumSize.width
        } else if minimumSize.width != UIViewNoIntrinsicMetric && maximumSize.width == UIViewNoIntrinsicMetric { // only min defined
            viewWidth = max(minimumSize.width, viewSize.width)
            widthToFit = viewWidth
        } else if minimumSize.width == UIViewNoIntrinsicMetric && maximumSize.width != UIViewNoIntrinsicMetric { // only max defined
            viewWidth = min(maximumSize.width, viewSize.width)
            widthToFit = maximumSize.width
        } else { // neither defined
            viewWidth = viewSize.width
            widthToFit = viewWidth
        }
        
        let viewHeight: CGFloat
        let heightToFit: CGFloat
     
        if minimumSize.height != UIViewNoIntrinsicMetric && maximumSize.height != UIViewNoIntrinsicMetric { // max and min defined
            viewHeight = max(min(maximumSize.height, viewSize.height), minimumSize.height)
            heightToFit = maximumSize.height
        } else if minimumSize.height != UIViewNoIntrinsicMetric && maximumSize.height == UIViewNoIntrinsicMetric { // only min defined
            viewHeight = max(minimumSize.height, viewSize.height)
            heightToFit = viewHeight
        } else if minimumSize.height == UIViewNoIntrinsicMetric && maximumSize.height != UIViewNoIntrinsicMetric { // only max defined
            viewHeight = min(maximumSize.height, viewSize.height)
            heightToFit = maximumSize.height
        } else { // neither defined
            viewHeight = viewSize.height
            heightToFit = viewHeight
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
        
        let fitFrame = CGRect(x: round(x), y: round(y), width: ceil(viewWidth), height: ceil(viewHeight))
        if apply {
            frame = fitFrame
        }
        return fitFrame
    }
    
    public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize = NoIntrinsicSize, minimumSize: CGSize = NoIntrinsicSize, horizontalAlignment: HorizontalAlignment, apply: Bool) -> CGRect {
        return wmf_preferredFrame(at: point, maximumSize: maximumSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, verticalAlignment: .top, apply: apply)
    }
    
    public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize, minimumSize: CGSize = NoIntrinsicSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let horizontalAlignment: HorizontalAlignment = semanticContentAttribute == .forceRightToLeft ? .right : .left
        return wmf_preferredFrame(at: point, maximumSize: maximumSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, apply: apply)
    }

    public func wmf_preferredFrame(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIViewNoIntrinsicMetric, horizontalAlignment: HorizontalAlignment, apply: Bool) -> CGRect {
        let minimumSize = CGSize(width: minimumWidth, height: UIViewNoIntrinsicMetric)
        let maximumSize = CGSize(width: maximumWidth, height: UIViewNoIntrinsicMetric)
        return wmf_preferredFrame(at: point, maximumSize: maximumSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, apply: apply)
    }
    
    public func wmf_preferredFrame(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIViewNoIntrinsicMetric, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let horizontalAlignment: HorizontalAlignment = semanticContentAttribute == .forceRightToLeft ? .right : .left
        return wmf_preferredFrame(at: point, maximumWidth: maximumWidth, minimumWidth: minimumWidth, horizontalAlignment: horizontalAlignment, apply: apply)
    }
    
    public func wmf_preferredHeight(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIViewNoIntrinsicMetric, alignedBy semanticContentAttribute: UISemanticContentAttribute, spacing: CGFloat, apply: Bool) -> CGFloat {
        return wmf_preferredFrame(at: point, maximumWidth: maximumWidth, minimumWidth: minimumWidth, alignedBy: semanticContentAttribute, apply: apply).layoutHeight(with: spacing)
    }
    
    public func wmf_preferredHeight(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIViewNoIntrinsicMetric, horizontalAlignment: HorizontalAlignment, spacing: CGFloat, apply: Bool) -> CGFloat {
        return wmf_preferredFrame(at: point, maximumWidth: maximumWidth, minimumWidth: minimumWidth, horizontalAlignment: horizontalAlignment, apply: apply).layoutHeight(with: spacing)
    }
}

extension UIButton {
    public override func wmf_sizeThatFits(_ maximumSize: CGSize) -> CGSize {
        var buttonAdjustedSize = maximumSize
        var heightAdjustment = contentEdgeInsets.top + contentEdgeInsets.bottom
        var widthAdjustment = contentEdgeInsets.left + contentEdgeInsets.right
        
        if let image = image(for: .normal) {
            heightAdjustment += imageEdgeInsets.top + imageEdgeInsets.bottom + image.size.height
            widthAdjustment += imageEdgeInsets.left + imageEdgeInsets.right + image.size.width
        }
        
        heightAdjustment += titleEdgeInsets.top + titleEdgeInsets.bottom
        widthAdjustment += titleEdgeInsets.left + titleEdgeInsets.right
        
        if buttonAdjustedSize.width != UIViewNoIntrinsicMetric {
            buttonAdjustedSize.width = buttonAdjustedSize.width - widthAdjustment
        }
        
        if buttonAdjustedSize.height != UIViewNoIntrinsicMetric {
            buttonAdjustedSize.height = buttonAdjustedSize.height - heightAdjustment
        }
        
        let buttonLabelSize: CGSize
        if let titleLabel = titleLabel {
            buttonLabelSize = titleLabel.sizeThatFits(buttonAdjustedSize)
        } else {
            buttonLabelSize = .zero
        }
        
        return CGSize(width: buttonLabelSize.width + widthAdjustment, height: buttonLabelSize.height + heightAdjustment)
    }
}

extension AlignedImageButton {
    override public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize = NoIntrinsicSize, minimumSize: CGSize = NoIntrinsicSize, horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: VerticalAlignment = .center, apply: Bool = false) -> CGRect  {
        let adjustedPoint = CGPoint(x: point.x - leftPadding, y: point.y - verticalPadding)
        var adjustedSize = maximumSize
        if adjustedSize.width != UIViewNoIntrinsicMetric {
            adjustedSize.width = adjustedSize.width + leftPadding + rightPadding
        }
        if adjustedSize.height != UIViewNoIntrinsicMetric {
            adjustedSize.height = adjustedSize.height + 2 * verticalPadding
        }
        return super.wmf_preferredFrame(at: adjustedPoint, maximumSize: adjustedSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment, apply: apply)
    }
}

