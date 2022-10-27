import Foundation

extension NSString {

    /// Find all ranges of occurrences of substring
    /// - Parameters:
    ///   - term: the substring to search for
    ///   - options: `NSRegularExpression.Options` to use in the search
    /// - Returns: An array of ranges matching the term in `self`
    func ranges(of term: String, options: NSRegularExpression.Options = [.caseInsensitive]) -> [NSRange] {
        guard let regex = try? NSRegularExpression(pattern: term, options: options) else {
            return []
        }

        let matches = regex.matches(in: (self as String), range: NSRange(location: 0, length: length))
        let ranges: [NSRange] = matches.compactMap { $0.range }

        return ranges
    }

}
