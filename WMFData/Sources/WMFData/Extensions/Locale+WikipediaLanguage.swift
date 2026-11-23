import Foundation

public extension Locale {

    /// Wikipedia language codes whose meaning differs from the ISO 639 code that `Locale` understands.
    /// Keys are Wikipedia subdomain codes, values are the ISO 639 codes to use for `Locale` lookups.
    ///
    /// "als" is Alemannisch on Wikipedia, but ISO 639-3 assigns "als" to Albanian (Tosk), so `Locale`
    /// would display it as "Albanian". The standard code for Alemannic German is "gsw".
    /// https://phabricator.wikimedia.org/T398296
    private static let localeLanguageCodeOverrides: [String: String] = [
        "als": "gsw"
    ]

    /// Returns the localized display name for a Wikipedia language code, accounting for Wikipedia
    /// codes that conflict with ISO 639. Use this instead of `localizedString(forLanguageCode:)`
    /// whenever the code comes from a Wikipedia site rather than from the OS.
    func localizedString(forWikipediaLanguageCode languageCode: String) -> String? {
        let lookupCode = Self.localeLanguageCodeOverrides[languageCode] ?? languageCode
        return localizedString(forLanguageCode: lookupCode)
    }

    /// The name of a Wikipedia language in that language itself, such as "Español" for "es", with
    /// the same overrides as `localizedString(forWikipediaLanguageCode:)`. The first letter is
    /// capitalized with the language's own rules, because `Locale` gives some names in lowercase.
    static func nativeName(forWikipediaLanguageCode languageCode: String) -> String? {
        let lookupCode = localeLanguageCodeOverrides[languageCode] ?? languageCode
        let locale = Locale(identifier: lookupCode)
        guard let name = locale.localizedString(forLanguageCode: lookupCode), let first = name.first else {
            return nil
        }
        return String(first).uppercased(with: locale) + name.dropFirst()
    }
}
