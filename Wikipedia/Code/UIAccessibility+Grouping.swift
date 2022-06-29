extension UIAccessibility {
    public static func groupedAccessibilityLabel(for optionalStringArray: [String?]) -> String? {
        return optionalStringArray
            .compactMap { $0 }
            .filter { $0.wmf_hasNonWhitespaceText }
            .joined(separator: ", ") // Comma adds slight voice-over pause.
    }
}
