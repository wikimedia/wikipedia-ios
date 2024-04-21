import Foundation

extension String {
    private enum Tags {
        static let boldStart = "<b>"
        static let boldEnd = "</b>"
    }
    /// Applies a bold tag to the first portion of the string that matches the given string
    /// - Parameter matchingString: the string to search for and bold
    public mutating func applyBoldTag(to matchingString: String) {
        // NSString and NSRange are used here for better compatability with NSAttributedString
        guard let range = range(of: matchingString, options: .caseInsensitive) else {
            return
        }
        insert(contentsOf: Tags.boldStart, at: range.lowerBound)
        insert(contentsOf: Tags.boldEnd, at: index(range.upperBound, offsetBy: Tags.boldStart.count))
    }
}
