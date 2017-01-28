
import Foundation

extension MTLValueTransformer {
    class func wmf_keyExistsBoolValueTransformer() -> MTLValueTransformer {
        return MTLValueTransformer(usingForwardBlock:{ (value, success, error) in true })
    }
    class func wmf_dictionaryValueTransformer(of modelClass:Swift.AnyClass!) -> MTLValueTransformer {
        return MTLValueTransformer(usingForwardBlock:{ (value, success, error) in
            if let dict = value as! [AnyHashable : Any]! {
                do {
                    return try MTLJSONAdapter.model(of: modelClass, fromJSONDictionary: dict)
                } catch {
                    return nil
                }
            }
            return nil
        })
    }
    class func wmf_arrayValueTransformer(of modelClass:Swift.AnyClass!) -> MTLValueTransformer {
        return MTLValueTransformer(usingForwardBlock:{ (value, success, error) in
            if let array = value as! [Any]! {
                do {
                    return try MTLJSONAdapter.models(of: modelClass, fromJSONArray: array)
                } catch {
                    return nil
                }
            }
            return nil
        })
    }
}
