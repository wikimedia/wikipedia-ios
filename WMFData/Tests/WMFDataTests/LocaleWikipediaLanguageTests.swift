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

    func testWMFLanguageLocalizedNameUsesOverride() {
        let language = WMFLanguage(languageCode: "als", languageVariantCode: nil)
        XCTAssertFalse(language.localizedName.lowercased().contains("albanian"))
        XCTAssertNotEqual(language.localizedName, "als")
    }
}
