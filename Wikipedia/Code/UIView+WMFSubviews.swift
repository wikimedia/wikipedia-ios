
extension UIView {
    func wmf_firstSubviewOfType<T>(type:T.Type) -> T? {
        for subview in self.subviews {
            if subview is T {
                return subview as? T
            }
        }
        return nil
    }
}
