
extension UIView {
    func wmf_firstSubviewOfType<T>(type:T.Type) -> T? {
        for subview in self.subviews {
            if subview is T {
                return subview as? T
            }
        }
        return nil
    }
    
    func wmf_applySemanticContentAttributeToAllSubviewsRecursively() {
        for view in subviews {
            view.semanticContentAttribute = semanticContentAttribute
            view.wmf_applySemanticContentAttributeToAllSubviewsRecursively()
        }
    }
}
