
// MARK: - Extension for arrays comprised of UITextFields
extension Array where Element: UITextField {
    /// Determines whether all UITextFields in this array have had text characters entered into them.
    ///
    /// - Returns: Bool indicating whether all UITextFields in this array have had text characters entered into them.
    func wmf_allFieldsFilled() -> Bool {
        return self.first(where:{ $0.text?.characters.count == 0 }) == nil
    }
}
