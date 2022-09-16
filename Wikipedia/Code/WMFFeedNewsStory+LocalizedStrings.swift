import Foundation

extension WMFFeedNewsStory {
    @objc static func localizedPicturedText(forWikiLanguage languageCode: String?) -> String {
        return WMFLocalizedString("pictured", languageCode: languageCode, value: "pictured", comment: "Indicates the person or item is pictured (as in a news story).")
    }
}
