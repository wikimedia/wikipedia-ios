import Foundation

public extension MWKLanguageLinkController {
    func swiftCompatiblePreferredLanguageVariantCodeForLanguageCode(_ languageCode: String?) -> String? {
        return preferredLanguageVariantCode(forLanguageCode: languageCode)
    }
}
