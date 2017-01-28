
import Foundation

fileprivate extension Array where Element: ExpressibleByStringLiteral {
    func wmf_dictionary() -> [String:String] {
        var dict = [String:String]()
        for key in self {
            if let key = key as? String {
                dict[key] = key
            }
        }
        return dict
    }
}

extension MTLJSONSerializing {
    static func wmf_jsonKeyPathsByProperties(of object:MTLJSONSerializing) -> [String: String] {
        return Mirror(reflecting: object).children.flatMap({ $0.label }).wmf_dictionary()
    }
}
