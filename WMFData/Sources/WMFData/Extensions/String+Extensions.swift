import Foundation

public extension String {
    var spacesToUnderscores: String {
        return self.replacingOccurrences(of: " ", with: "_").precomposedStringWithCanonicalMapping
    }
    
    var underscoresToSpaces: String {
        return self.replacingOccurrences(of: "_", with: " ").precomposedStringWithCanonicalMapping
    }
    
    var unescapedUnderscoresToSpaces: String? {
        return removingPercentEncoding?.underscoresToSpaces
    }
}
