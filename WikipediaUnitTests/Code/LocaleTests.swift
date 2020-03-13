import XCTest
@testable import Wikipedia
@testable import WMF

class LocaleTests: XCTestCase {
    func testLanguageVariants() {
        let identifiers = ["sr-CYRL", "zh-hans-CN", "zh-hans", "en-US"]
        let preferredLanguages = Locale.uniqueWikipediaLanguages(with: identifiers, includingLanguagesWithoutVariants: false)
        XCTAssertEqual(["sr-ec", "zh-cn", "zh-hans"], preferredLanguages)
        
        let zhURL = URL(string: "https://zh.wikipedia.org")!
        let zhVariant = Locale.preferredWikipediaLanguageVariant(for: zhURL, preferredLanguages: preferredLanguages)
        XCTAssertEqual("zh-cn", zhVariant)
        
        let srURL = URL(string: "https://sr.wikipedia.org")!
        let srVariant = Locale.preferredWikipediaLanguageVariant(for: srURL, preferredLanguages: preferredLanguages)
        XCTAssertEqual("sr-ec", srVariant)
    }
}
