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
}
