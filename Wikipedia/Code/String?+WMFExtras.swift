extension Optional where Wrapped: ExpressibleByStringLiteral {
    /// Convenience method for optional String character count.
    /// Returns 0 for nil optional String *or* character count for non-nil optional String.
    var wmf_safeCharacterCount: Int {
        guard let value = self as? String else {
            return 0
        }
        return value.count
    }
}
