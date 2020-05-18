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

public let NoIntrinsicSize = CGSize(width: UIView.noIntrinsicMetric, height: UIView.noIntrinsicMetric)

extension UIView {
    @objc public func wmf_sizeThatFits(_ size: CGSize) -> CGSize {
        return sizeThatFits(size)
    }
    
    @objc @discardableResult public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize = NoIntrinsicSize, minimumSize: CGSize = NoIntrinsicSize, horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: VerticalAlignment = .center, apply: Bool = false) -> CGRect {
        let viewSize: CGSize = wmf_sizeThatFits(maximumSize)
       
        var x: CGFloat = point.x
        var y: CGFloat = point.y
        
        let viewWidth: CGFloat
        let widthToFit: CGFloat

        if minimumSize.width != UIView.noIntrinsicMetric && maximumSize.width != UIView.noIntrinsicMetric { // max and min defined
            viewWidth = max(min(maximumSize.width, viewSize.width), minimumSize.width)
            widthToFit = maximumSize.width
        } else if minimumSize.width != UIView.noIntrinsicMetric && maximumSize.width == UIView.noIntrinsicMetric { // only min defined
            viewWidth = max(minimumSize.width, viewSize.width)
            widthToFit = viewWidth
        } else if minimumSize.width == UIView.noIntrinsicMetric && maximumSize.width != UIView.noIntrinsicMetric { // only max defined
            viewWidth = min(maximumSize.width, viewSize.width)
            widthToFit = maximumSize.width
        } else { // neither defined
            viewWidth = viewSize.width
            widthToFit = viewWidth
        }
        
        let viewHeight: CGFloat
        let heightToFit: CGFloat
     
        if minimumSize.height != UIView.noIntrinsicMetric && maximumSize.height != UIView.noIntrinsicMetric { // max and min defined
            viewHeight = max(min(maximumSize.height, viewSize.height), minimumSize.height)
            heightToFit = maximumSize.height
        } else if minimumSize.height != UIView.noIntrinsicMetric && maximumSize.height == UIView.noIntrinsicMetric { // only min defined
            viewHeight = max(minimumSize.height, viewSize.height)
            heightToFit = viewHeight
        } else if minimumSize.height == UIView.noIntrinsicMetric && maximumSize.height != UIView.noIntrinsicMetric { // only max defined
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
    
    @discardableResult public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize = NoIntrinsicSize, minimumSize: CGSize = NoIntrinsicSize, horizontalAlignment: HorizontalAlignment, apply: Bool) -> CGRect {
        return wmf_preferredFrame(at: point, maximumSize: maximumSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, verticalAlignment: .top, apply: apply)
    }
    
    @discardableResult public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize, minimumSize: CGSize = NoIntrinsicSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let horizontalAlignment: HorizontalAlignment = semanticContentAttribute == .forceRightToLeft ? .right : .left
        return wmf_preferredFrame(at: point, maximumSize: maximumSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, apply: apply)
    }

    @discardableResult public func wmf_preferredFrame(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIView.noIntrinsicMetric, horizontalAlignment: HorizontalAlignment, apply: Bool) -> CGRect {
        let minimumSize = CGSize(width: minimumWidth, height: UIView.noIntrinsicMetric)
        let maximumSize = CGSize(width: maximumWidth, height: UIView.noIntrinsicMetric)
        return wmf_preferredFrame(at: point, maximumSize: maximumSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, apply: apply)
    }
    
    @discardableResult public func wmf_preferredFrame(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIView.noIntrinsicMetric, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let horizontalAlignment: HorizontalAlignment = semanticContentAttribute == .forceRightToLeft ? .right : .left
        return wmf_preferredFrame(at: point, maximumWidth: maximumWidth, minimumWidth: minimumWidth, horizontalAlignment: horizontalAlignment, apply: apply)
    }
    
    @discardableResult public func wmf_preferredHeight(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIView.noIntrinsicMetric, alignedBy semanticContentAttribute: UISemanticContentAttribute, spacing: CGFloat, apply: Bool) -> CGFloat {
        return wmf_preferredFrame(at: point, maximumWidth: maximumWidth, minimumWidth: minimumWidth, alignedBy: semanticContentAttribute, apply: apply).layoutHeight(with: spacing)
    }
    
    @discardableResult public func wmf_preferredHeight(at point: CGPoint, maximumWidth: CGFloat, minimumWidth: CGFloat = UIView.noIntrinsicMetric, horizontalAlignment: HorizontalAlignment, spacing: CGFloat, apply: Bool) -> CGFloat {
        return wmf_preferredFrame(at: point, maximumWidth: maximumWidth, minimumWidth: minimumWidth, horizontalAlignment: horizontalAlignment, apply: apply).layoutHeight(with: spacing)
    }
}

extension UIButton {
    public override func wmf_sizeThatFits(_ maximumSize: CGSize) -> CGSize {
        var buttonAdjustedSize = maximumSize
        var heightAdjustment = contentEdgeInsets.top + contentEdgeInsets.bottom
        var widthAdjustment = contentEdgeInsets.left + contentEdgeInsets.right
        
        var imageHeight: CGFloat = 0
        if let image = image(for: .normal) {
            widthAdjustment += imageEdgeInsets.left + imageEdgeInsets.right + image.size.width
            imageHeight = image.size.height + imageEdgeInsets.top + imageEdgeInsets.bottom + contentEdgeInsets.top + contentEdgeInsets.bottom
        }
        
        heightAdjustment += titleEdgeInsets.top + titleEdgeInsets.bottom
        widthAdjustment += titleEdgeInsets.left + titleEdgeInsets.right
        
        if buttonAdjustedSize.width != UIView.noIntrinsicMetric {
            buttonAdjustedSize.width = buttonAdjustedSize.width - widthAdjustment
        }
        
        if buttonAdjustedSize.height != UIView.noIntrinsicMetric {
            buttonAdjustedSize.height = buttonAdjustedSize.height - heightAdjustment
        }
        
        let buttonLabelSize: CGSize
        if let titleLabel = titleLabel {
            buttonLabelSize = titleLabel.sizeThatFits(buttonAdjustedSize)
        } else {
            buttonLabelSize = .zero
        }
        
        let maxHeight = max(imageHeight, buttonLabelSize.height + heightAdjustment)
        return CGSize(width: buttonLabelSize.width + widthAdjustment, height: maxHeight)
    }
}

extension AlignedImageButton {
    @discardableResult override public func wmf_preferredFrame(at point: CGPoint, maximumSize: CGSize = NoIntrinsicSize, minimumSize: CGSize = NoIntrinsicSize, horizontalAlignment: HorizontalAlignment = .center, verticalAlignment: VerticalAlignment = .center, apply: Bool = false) -> CGRect  {
        let adjustedPoint = CGPoint(x: point.x - leftPadding, y: point.y - verticalPadding)
        var adjustedSize = maximumSize
        if adjustedSize.width != UIView.noIntrinsicMetric {
            adjustedSize.width = adjustedSize.width + leftPadding + rightPadding
        }
        if adjustedSize.height != UIView.noIntrinsicMetric {
            adjustedSize.height = adjustedSize.height + 2 * verticalPadding
        }
        return super.wmf_preferredFrame(at: adjustedPoint, maximumSize: adjustedSize, minimumSize: minimumSize, horizontalAlignment: horizontalAlignment, verticalAlignment: verticalAlignment, apply: apply)
    }
}

