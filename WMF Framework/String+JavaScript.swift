import Foundation

public extension String {
    /// Can use ES6 backticks ` now instead of  apostrophes.
    /// Doing so means we *only* have to escape backticks instead of apostrophes, quotes and line breaks.
    /// (May consider switching other native-to-JS messaging to do same later.)
    var sanitizedForJavaScriptTemplateLiterals: String {
        return replacingOccurrences(of: "([\\\\{}\\`])", with: "\\\\$1", options: [.regularExpression])
    }
}

