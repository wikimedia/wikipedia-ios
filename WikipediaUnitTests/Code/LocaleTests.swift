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
    
    func testLocaleHeader() {
        let languages = Locale.uniqueWikipediaLanguages(with: ["en-US", "zh-Hans-US", "zh-Hant-US", "zh-Hant-TW", "en-GB"])
        let expectedResult = ["en-us", "zh-hans", "zh-hant", "zh-tw", "en-gb"]
        XCTAssertEqual(languages, expectedResult)
        
        let header = Locale.acceptLanguageHeaderForLanguageCodes(languages)
        XCTAssertEqual(header, "en-us, zh-hans;q=0.8, zh-hant;q=0.6, zh-tw;q=0.4, en-gb;q=0.2")
    }
    
    func testZHHeaders() {
        let languages = Locale.uniqueWikipediaLanguages(with: ["zh-Hans-CN", "zh-Hans-SG", "zh-Hant-MO", "zh-Hant-TW", "zh-Hant-HK"])
        let expectedResult = ["zh-cn", "zh-sg", "zh-mo", "zh-tw", "zh-hk"]
        XCTAssertEqual(languages, expectedResult)
        
        let header = Locale.acceptLanguageHeaderForLanguageCodes(languages)
        XCTAssertEqual(header, "zh-cn, zh-sg;q=0.8, zh-mo;q=0.6, zh-tw;q=0.4, zh-hk;q=0.2")
    }
}
