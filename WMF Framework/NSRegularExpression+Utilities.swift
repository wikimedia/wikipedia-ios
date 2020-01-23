public extension NSRegularExpression {
    func firstMatch(in string: String) -> NSTextCheckingResult? {
        return firstMatch(in: string, options: [], range: string.fullRange)
    }
    
    func firstReplacementString(in string: String, template: String = "$1") -> String? {
        guard let result = firstMatch(in: string)
        else {
            return nil
        }
        return replacementString(for: result, in: string, offset: 0, template: template)
    }
    
    func stringByReplacingMatches(in string: String, options: NSRegularExpression.MatchingOptions = [], template: String? = nil, with block: (String) -> String) -> String {
        let mutableString = NSMutableString(string: string)
        var offset = 0
        enumerateMatches(in: string, options: options, range: string.fullRange) { (result, flags, stop) in
            guard let result = result else {
                return
            }
            let fullMatch = replacementString(for: result, in: string, offset: 0, template: "$0")
            let templateMatch: String
            if let template = template {
                templateMatch = replacementString(for: result, in: string, offset: 0, template: template)
            } else {
                templateMatch = fullMatch
            }
            let replacement = block(templateMatch)
            mutableString.replaceCharacters(in: NSMakeRange(result.range.location + offset, result.range.length), with: replacement)
            let delta = fullMatch.count - replacement.count
            offset += delta
        }
        return mutableString as String
    }
}
