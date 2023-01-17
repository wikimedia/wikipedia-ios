import Foundation

extension NSMutableAttributedString {
    /// Removes unnecessary `\n` initial new line characters
    public func removingInitialNewlineCharacters() -> Self {
        if string.first == "\n" {
            while string.first == "\n" {
                let range = (string as NSString).range(of: "\n")
                deleteCharacters(in: range)
            }
        }
        return self
    }
    
    /// When there are more than two consecutive `\n` newline characters (there may be other whitespace between the newlines), removes all but two occurances
    public func removingRepetitiveNewlineCharacters() -> Self {
        var range = (string as NSString).range(of: "(\\s*\\n){3,}", options: .regularExpression)
        while NSMaxRange(range) != NSNotFound {
            replaceCharacters(in: range, with: "\n\n")
            range = (string as NSString).range(of: "(\\s*\\n){3,}", options: .regularExpression)
        }
        return self
    }
}
