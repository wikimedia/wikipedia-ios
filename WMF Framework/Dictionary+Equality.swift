import Foundation

public extension Dictionary where Key: Equatable {
    func wmf_isEqualTo<C: Collection>(_ dictionary: Dictionary, excluding excludedKeys: C? = nil) -> Bool where C.Element == Key {
        guard let excludedKeys = excludedKeys else {
            return (self as NSDictionary).isEqual(to: dictionary)
        }
        let left = filter({ !excludedKeys.contains($0.key) })
        let right = dictionary.filter({ !excludedKeys.contains($0.key) })
        return (left as NSDictionary).isEqual(to: right)
    }
}
