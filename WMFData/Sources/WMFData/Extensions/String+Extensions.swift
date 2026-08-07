import Foundation

public extension String {
    var spacesToUnderscores: String {
        return self.replacingOccurrences(of: " ", with: "_")
    }
    
    var underscoresToSpaces: String {
        return self.replacingOccurrences(of: "_", with: " ")
    }

    /// A page title made fit to show to a reader.
    ///
    /// Titles reach us in database form: words joined by underscores, and accented characters
    /// sometimes decomposed into a letter plus a combining mark. Both need undoing before display,
    /// the second so that equal-looking titles also compare and sort as equal.
    var normalizedForDisplay: String {
        return self.underscoresToSpaces.precomposedStringWithCanonicalMapping
    }
}
