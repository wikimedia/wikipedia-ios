extension UIView {
    public var wmf_effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 10.0, *) {
            return self.effectiveUserInterfaceLayoutDirection
        } else {
            return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        }
    }
}

extension UIView {
    public func wmf_prefferedFrame(at point: CGPoint, fitting size: CGSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
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
    
    @objc(wmf_prefferedFrameAtPoint:fittingAvailableWidth:alignedBySemanticContentAttribute:apply:)
    public func wmf_prefferedFrame(at point: CGPoint, fitting availableWidth: CGFloat, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        let size = CGSize(width: availableWidth, height: CGFloat.greatestFiniteMagnitude)
        return self.wmf_prefferedFrame(at: point, fitting: size, alignedBy: semanticContentAttribute, apply: apply)
    }
}

extension UILabel {
    public override func wmf_prefferedFrame(at point: CGPoint, fitting size: CGSize, alignedBy semanticContentAttribute: UISemanticContentAttribute, apply: Bool) -> CGRect {
        guard self.wmf_hasText else {
            return .zero
        }
        return super.wmf_prefferedFrame(at: point, fitting: size, alignedBy: semanticContentAttribute, apply: apply)
    }
}
