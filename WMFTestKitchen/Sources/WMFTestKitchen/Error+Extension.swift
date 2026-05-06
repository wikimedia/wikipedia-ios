import Foundation

public extension Error {
    var logDescription: String {
        let nsError = self as NSError
        let typeName = String(reflecting: type(of: self))
        
        if nsError.domain == typeName {
            // Swift error — log case name only
            let caseName = Mirror(reflecting: self).children.first?.label ?? String(describing: self)
            return "\(typeName).\(caseName)"
        } else {
            // NSError — log domain/code only
            return "\(nsError.domain).\(nsError.code)"
        }
    }
}
