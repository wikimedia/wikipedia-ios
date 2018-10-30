import Foundation

extension String {
    var withDotPrefix: String {
        return "." + self
    }
    
    public func isDomainOrSubDomainOf(_ domain: String) -> Bool {
        return self == domain || self.hasSuffix(domain.withDotPrefix)
    }
}
