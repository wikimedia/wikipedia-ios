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

    /// Recursively searches the view hierarchy for the first descendant of the given type.
    func firstDescendant<T>(ofType type: T.Type) -> T? {
        for subview in subviews {
            if let match = subview as? T { return match }
            if let match = subview.firstDescendant(ofType: type) { return match }
        }
        return nil
    }
}
