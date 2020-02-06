extension CharacterSet {
    public static var articleTitlePathComponentAllowed: CharacterSet {
        return NSCharacterSet.wmf_URLArticleTitlePathComponentAllowed()
    }

    static let urlQueryComponentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlQueryAllowed
        characterSet.remove(charactersIn: "+&=")
        return characterSet
    }()
    
    public static let pathAndFragmentAllowed: CharacterSet = {
        var characterSet = CharacterSet.urlPathAllowed
        characterSet.insert(charactersIn: "#")
        return characterSet
    }()
}
