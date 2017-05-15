extension UIView {
    public var wmf_effectiveUserInterfaceLayoutDirection: UIUserInterfaceLayoutDirection {
        if #available(iOS 10.0, *) {
            return self.effectiveUserInterfaceLayoutDirection
        } else {
            return UIView.userInterfaceLayoutDirection(for: semanticContentAttribute)
        }
    }
    public var wmf_isRightToLeft: Bool {
        return semanticContentAttribute == .forceRightToLeft || wmf_effectiveUserInterfaceLayoutDirection == .rightToLeft
    }
}
