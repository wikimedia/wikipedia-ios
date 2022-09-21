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
}
