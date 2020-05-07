extension CharacterSet {
    public static var encodeURIComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_encodeURIComponentAllowed()
    }
    
    public static var relativePathAndFragmentAllowed: CharacterSet {
        return NSCharacterSet.wmf_relativePathAndFragmentAllowed()
    }
    
    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
}
