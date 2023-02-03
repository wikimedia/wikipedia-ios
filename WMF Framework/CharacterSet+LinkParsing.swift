extension CharacterSet {
    public static var encodeURIComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_encodeURIComponentAllowed()
    }
    
    public static var relativePathAndFragmentAllowed: CharacterSet {
        return NSCharacterSet.wmf_relativePathAndFragmentAllowed()
    }
    
    // RFC 3986 reserved + unreserved characters + percent (%)
    public static var rfc3986Allowed: CharacterSet {
        return CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~:/?#[]@!$&'()*+,;=%")
    }
    
    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
}
