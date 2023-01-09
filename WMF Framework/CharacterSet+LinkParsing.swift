extension CharacterSet {
    public static var encodeURIComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_encodeURIComponentAllowed()
    }
    
    public static var relativePathAndFragmentAllowed: CharacterSet {
        return NSCharacterSet.wmf_relativePathAndFragmentAllowed()
    }
    
    public static var ascii: CharacterSet {
        return CharacterSet(charactersIn: Unicode.Scalar(0)..<Unicode.Scalar(128))
    }
    
    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
}
