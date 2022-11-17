import Foundation

public extension NSUserActivity {
    @objc var shouldSkipOnboarding: Bool {
        guard let path = webpageURL?.wikiResourcePath,
              let languageCode = webpageURL?.wmf_languageCode else {
            return false
        }

        let namespaceAndTitle = path.namespaceAndTitleOfWikiResourcePath(with: languageCode)
        let namespace = namespaceAndTitle.0
        let title = namespaceAndTitle.1

        return namespace == .special && title == "ReadingLists"
    }
}
