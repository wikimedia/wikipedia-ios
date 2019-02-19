
// MARK: - Extension for arrays comprised of UITextFields
extension Array where Element: UITextField {
    /// Determines whether all UITextFields in this array have had text characters entered into them.
    ///
    /// - Returns: Bool indicating whether all UITextFields in this array have had text characters entered into them.
    func wmf_allFieldsFilled() -> Bool {
        let emptyElement: UITextField? = first { (element) -> Bool in
            guard let text = element.text else {
                return true
            }
            return text.isEmpty
        }
        return emptyElement == nil
    }
}
