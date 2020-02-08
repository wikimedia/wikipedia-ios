extension CharacterSet {
    public static var articleTitlePathComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_URLArticleTitlePathComponentAllowed()
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
