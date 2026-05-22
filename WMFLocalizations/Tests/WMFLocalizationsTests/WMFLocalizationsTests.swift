import XCTest
@testable import WMFNativeLocalizations
@testable import WMFTranslateWikiLocalizations

final class WMFLocalizationsTests: XCTestCase {

    func testWMFLocalizedStringResolvesKnownEnglishKey() {
        // "search-title" is defined in the en.lproj Localizable.strings with the value "Search".
        let result = WMFLocalizedString("search-title", value: "Search", comment: "")
        XCTAssertEqual(result, "Search")
    }

    func testWMFLocalizedStringFallsBackToValueForUnknownKey() {
        // For a key that exists in no bundle, the function should fall back to the supplied `value:`.
        let result = WMFLocalizedString("wmf-localizations-tests-nonexistent-key", value: "fallback", comment: "")
        XCTAssertEqual(result, "fallback")
    }
}
