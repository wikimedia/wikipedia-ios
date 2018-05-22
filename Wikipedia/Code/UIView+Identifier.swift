extension UIView {
    @objc static func identifier() -> String {
        return String(describing: self)
    }
}
