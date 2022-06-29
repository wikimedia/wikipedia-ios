extension UIView {
    func wmf_firstSubviewOfType<T>(_ type:T.Type) -> T? {
        for subview in self.subviews {
            if subview is T {
                return subview as? T
            }
        }
        return nil
    }
    
    func wmf_firstSuperviewOfType<T>(_ type: T.Type) -> T? {
        return superview as? T ?? superview.flatMap { $0.wmf_firstSuperviewOfType(type) }
    }

}
