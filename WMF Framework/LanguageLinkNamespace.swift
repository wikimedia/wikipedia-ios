
import UIKit

@objc(WMFLanguageLinkNamespace)
public class LanguageLinkNamespace: NSObject {
    public let canonicalName: String
    
    @objc init(canonicalName: String) {
        self.canonicalName = canonicalName
    }
    
    override public func isEqual(_ object: Any?) -> Bool {
        
        if let rhs = object as? LanguageLinkNamespace {
            return self.canonicalName == rhs.canonicalName
        }
        
        return false
    }
}
