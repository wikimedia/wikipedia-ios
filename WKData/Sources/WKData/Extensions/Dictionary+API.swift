import Foundation

extension Dictionary where Key == String, Value == Any {
    
    func encodedForAPI() -> [String: Any] {
        var returnDict: [String: Any] = [:]
        
        for (key, value) in self {
            
            guard
                let encodedName = key.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryComponentAllowed),
                let encodedValue = (value as? String)?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryComponentAllowed) else {
                    continue
            }
            
            returnDict[encodedName] = encodedValue
        }
        
        return returnDict
    }
}
