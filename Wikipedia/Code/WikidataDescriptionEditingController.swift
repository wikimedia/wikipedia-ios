@objc public class WikidataDescriptionEditingController: NSObject {
    private var blacklistedLanguages = Set<String>()

    @objc public func setBlacklistedLanguages(_ blacklistedLanguagesFromRemoteConfig: Array<String>) {
        blacklistedLanguages = Set(blacklistedLanguagesFromRemoteConfig)
    }

    public func isBlacklisted(_ languageCode: String) -> Bool {
        guard !blacklistedLanguages.isEmpty else {
            return false
        }
        return blacklistedLanguages.contains(languageCode)
    }
}
}
