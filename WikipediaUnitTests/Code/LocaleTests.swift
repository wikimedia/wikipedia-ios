import XCTest
@testable import Wikipedia
@testable import WMF

class LocaleTests: XCTestCase {
    func testLanguageVariants() {
        let identifiers = ["sr-CYRL", "zh-hant-CN", "zh-hans", "en-US"]
        let preferredLanguages = Locale.uniqueWikipediaLanguages(with: identifiers, includingLanguagesWithoutVariants: false)
        XCTAssertEqual(["sr-Cyrl", "zh-Hant-HK", "zh-Hans"], preferredLanguages)
        
        let zhURL = URL(string: "https://zh.wikipedia.org")!
        let zhVariant = Locale.preferredWikipediaLanguageVariant(for: zhURL, preferredLanguages: preferredLanguages)
        XCTAssertEqual("zh-Hant-HK", zhVariant)
        
        let srURL = URL(string: "https://sr.wikipedia.org")!
        let srVariant = Locale.preferredWikipediaLanguageVariant(for: srURL, preferredLanguages: preferredLanguages)
        XCTAssertEqual("sr-Cyrl", srVariant)
    }
    
    func testLocaleHeader() {
        let languages = Locale.uniqueWikipediaLanguages(with: ["en-US", "zh-Hans-US", "zh-Hant-US", "zh-Hant-TW", "en-GB"])
        let expectedResult = ["en-us",  "zh-Hans", "zh-Hant-HK", "zh-Hant-TW", "en-gb"]
        XCTAssertEqual(languages, expectedResult)
        
        let header = Locale.acceptLanguageHeaderForLanguageCodes(languages)
        XCTAssertEqual(header, "en-us, zh-Hans;q=0.8, zh-Hant-HK;q=0.6, zh-Hant-TW;q=0.4, en-gb;q=0.2")
    }
    
    func testZHHeaders() {
        let languages = Locale.uniqueWikipediaLanguages(with: ["zh-Hans", "zh-Hans-SG", "zh-Hant-MO", "zh-Hant-TW", "zh-Hant-HK"])
        let expectedResult = ["zh-Hans", "zh-Hans-SG", "zh-Hant-MO", "zh-Hant-TW", "zh-Hant-HK"]
        XCTAssertEqual(languages, expectedResult)
        
        let header = Locale.acceptLanguageHeaderForLanguageCodes(languages)
        XCTAssertEqual(header, "zh-Hans, zh-Hans-SG;q=0.8, zh-Hant-MO;q=0.6, zh-Hant-TW;q=0.4, zh-Hant-HK;q=0.2")
    }
}
