
extension UIView {
    func wmf_firstSubviewOfType<T>(_ type:T.Type) -> T? {
        for subview in self.subviews {
            if subview is T {
                return subview as? T
            }
        }
        return nil
    }
}
