
extension Optional where Wrapped: ExpressibleByStringLiteral {
    /// Returns character count for optional strings. Returns 0 if the optional is nil or the string is empty. Mostly a convenience so you don't have to do the unwrapping dance just to see if you have a non-zero length string.
    var wmf_safeCharacterCount: Int {
        get {
            if let value = self as? String, !value.isEmpty {
                return value.characters.count
            }
            return 0
        }
    }
}
