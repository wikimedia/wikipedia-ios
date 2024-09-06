import Foundation

public extension String {
    var spacesToUnderscores: String {
        return self.replacingOccurrences(of: " ", with: "_")
    }
    
    var underscoresToSpaces: String {
        return self.replacingOccurrences(of: "_", with: " ")
    }
}
