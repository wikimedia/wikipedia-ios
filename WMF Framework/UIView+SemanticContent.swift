extension UIView {
    public var wmf_effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 10.0, *) {
            return self.effectiveUserInterfaceLayoutDirection
        } else {
            return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        }
    }
    
    public func wmf_preferredFrame(at point: CGPoint, fitting size: CGSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let viewSize = sizeThatFits(size)
        var actualX = point.x
        let actualWidth = min(viewSize.width, size.width)
        if semanticContentAttribute == .forceRightToLeft {
            actualX = point.x + size.width - actualWidth
        }
        let fitFrame = CGRect(x: actualX, y: point.y, width: actualWidth, height: viewSize.height)
        if apply {
            frame = fitFrame
        }
        return fitFrame
    }
    
    @objc(wmf_preferredFrameAtPoint:fittingAvailableWidth:alignedBySemanticContentAttribute:apply:)
    public func wmf_preferredFrame(at point: CGPoint, fitting availableWidth: CGFloat, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let size = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
        return self.wmf_preferredFrame(at: point, fitting: size, alignedBy: semanticContentAttribute, apply: apply)
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
