import XCTest
@testable import WMFData

final class LocaleWikipediaLanguageTests: XCTestCase {

    private let locale = Locale(identifier: "en")

    func testAlemannischIsNotDisplayedAsAlbanian() {
        let name = locale.localizedString(forWikipediaLanguageCode: "als")
        XCTAssertNotNil(name)
        XCTAssertEqual(name, locale.localizedString(forLanguageCode: "gsw"))
        XCTAssertFalse(name?.lowercased().contains("albanian") ?? true)
    }

    func testCodesWithoutOverrideFallThroughToLocale() {
        for code in ["de", "en", "no", "zh"] {
            XCTAssertEqual(locale.localizedString(forWikipediaLanguageCode: code), locale.localizedString(forLanguageCode: code), code)
        }
    }

    func testUnknownCodeReturnsSameResultAsLocale() {
        XCTAssertEqual(locale.localizedString(forWikipediaLanguageCode: "test"), locale.localizedString(forLanguageCode: "test"))
    }

    // MARK: - Native names

    /// Like Android's Home language menu, each language is named in that language itself.
    func testNativeNameIsInTheLanguageItself() {
        XCTAssertEqual(Locale.nativeName(forWikipediaLanguageCode: "ar"), Locale(identifier: "ar").localizedString(forLanguageCode: "ar"))
        XCTAssertEqual(Locale.nativeName(forWikipediaLanguageCode: "de"), "Deutsch")
        XCTAssertEqual(Locale.nativeName(forWikipediaLanguageCode: "en"), "English")
    }

    /// `Locale` names some languages in lowercase, such as "español" and "português".
    func testNativeNameStartsWithACapital() {
        XCTAssertEqual(Locale.nativeName(forWikipediaLanguageCode: "es"), "Español")
        XCTAssertEqual(Locale.nativeName(forWikipediaLanguageCode: "pt"), "Português")
    }

    func testNativeNameUsesTheOverride() {
        let name = Locale.nativeName(forWikipediaLanguageCode: "als")
        XCTAssertEqual(name, Locale.nativeName(forWikipediaLanguageCode: "gsw"))
        XCTAssertFalse(name?.lowercased().contains("shqip") ?? true, "als is Alemannisch, not Albanian")
    }

    func testWMFLanguageNativeNameFallsBackToLocalizedName() {
        let language = WMFLanguage(languageCode: "test", languageVariantCode: nil)
        XCTAssertEqual(language.nativeName, Locale.nativeName(forWikipediaLanguageCode: "test") ?? language.localizedName)
        XCTAssertFalse(language.nativeName.isEmpty)
    }

    func testWMFLanguageLocalizedNameUsesOverride() {
        let language = WMFLanguage(languageCode: "als", languageVariantCode: nil)
        XCTAssertFalse(language.localizedName.lowercased().contains("albanian"))
        XCTAssertNotEqual(language.localizedName, "als")
    }
}
