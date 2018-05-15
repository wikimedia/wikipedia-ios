import Foundation

public extension Dictionary where Key: Equatable {
    func wmf_isEqualTo<C: Collection>(_ dictionary: Dictionary, excluding excludedKeys: C? = nil) -> Bool where C.Element == Key {
        guard let excludedKeys = excludedKeys else {
            return NSDictionary(dictionary: self).isEqual(to: dictionary)
        }
        let left = filter({ !excludedKeys.contains($0.key) })
        let right = dictionary.filter({ !excludedKeys.contains($0.key) })
        return NSDictionary(dictionary: left).isEqual(to: right)
    }
}
