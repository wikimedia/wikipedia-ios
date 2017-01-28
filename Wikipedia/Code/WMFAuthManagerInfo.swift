
import Foundation

class WMFAuthManagerInfo2: MTLModel, MTLJSONSerializing {
    var canauthenticatenow: Bool = false
    var cancreateaccounts: Bool = false
    var preservedusername: Bool = false
    var requests: [WMFAuthRequest]? = []
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFAuthManagerInfo2())
    }
    class func canauthenticatenowJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_keyExistsBoolValueTransformer()
    }
    class func cancreateaccountsJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_keyExistsBoolValueTransformer()
    }
    class func preservedusernameJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_keyExistsBoolValueTransformer()
    }
    class func requestsJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_arrayValueTransformer(of: WMFAuthRequest.self)
    }
}

class WMFAuthRequest: MTLModel, MTLJSONSerializing {
    var id: String?
    var metadata: WMFAuthMetadata?
    var required: String?
    var provider: String?
    var account: String?
    var fields: WMFAuthFields?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFAuthRequest())
    }
    class func metadataJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_dictionaryValueTransformer(of: WMFAuthMetadata.self)
    }
    class func fieldsJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_dictionaryValueTransformer(of: WMFAuthFields.self)
    }
}

class WMFAuthMetadata: MTLModel, MTLJSONSerializing {
    var type: String?
    var mime: String?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFAuthMetadata())
    }
}

class WMFAuthFields: MTLModel, MTLJSONSerializing {
    var captchaId: WMFAuthField?
    var captchaInfo: WMFAuthField?
    var captchaWord: WMFAuthField?
    var username: WMFAuthField?
    var password: WMFAuthField?
    var retype: WMFAuthField?
    var campaign: WMFAuthField?
    var email: WMFAuthField?
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFAuthFields())
    }
}

class WMFAuthField: MTLModel, MTLJSONSerializing {
    var type: String?
    var value: String?
    var label: String?
    var help: String?
    var optional: Bool = false
    var sensitive: Bool = false
    public static func jsonKeyPathsByPropertyKey() -> [AnyHashable : Any]!{
        return wmf_jsonKeyPathsByProperties(of: WMFAuthField())
    }
    class func optionalJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_keyExistsBoolValueTransformer()
    }
    class func sensitiveJSONTransformer() -> ValueTransformer {
        return MTLValueTransformer.wmf_keyExistsBoolValueTransformer()
    }
}
