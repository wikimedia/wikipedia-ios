import XCTest
@testable import Wikipedia
@testable import WMF

class LocaleTests: XCTestCase {
    func testLanguageVariants() {
        let identifiers = ["sr-CYRL", "zh-hans-CN", "zh-hans", "en-US"]
        let preferredLanguages = Configuration.uniqueWikipediaLanguages(with: identifiers, includingLanguagesWithoutVariants: false)
        XCTAssertEqual(["sr-ec", "zh-cn", "zh-hans"], preferredLanguages)
        
        let configuration = Configuration.productionConfiguration(with: preferredLanguages)
        let zhURL = URL(string: "https://zh.wikipedia.org")!
        let zhVariant = configuration.preferredWikipediaLanguageVariant(for: zhURL.wmf_language)
        XCTAssertEqual("zh-cn", zhVariant)
        
        let srURL = URL(string: "https://sr.wikipedia.org")!
        let srVariant = configuration.preferredWikipediaLanguageVariant(for: srURL.wmf_language)
        XCTAssertEqual("sr-ec", srVariant)
    }
    
    func testLocaleHeaders() {
        let languages = Configuration.uniqueWikipediaLanguages(with: ["en-US", "zh-Hans-US", "zh-Hant-US", "zh-Hant-TW", "en-GB"])
        let expectedResult = ["en-us", "zh-hans", "zh-hant", "zh-tw", "en-gb"]
        XCTAssertEqual(languages, expectedResult, "Should be filtered down to wiki language codes")
        let header = Configuration.acceptLanguageHeader(with: languages)
        XCTAssertEqual(header, "en-us, zh-hans;q=0.8, zh-hant;q=0.6, zh-tw;q=0.4, en-gb;q=0.2", "Accept-language header value should be correct")
    }
    
    func testZHHeaders() {
        let languages = Configuration.uniqueWikipediaLanguages(with: ["zh-Hans-CN", "zh-Hans-SG", "zh-Hant-MO", "zh-Hant-TW", "zh-Hant-HK"])
        let expectedResult = ["zh-cn", "zh-sg", "zh-mo", "zh-tw", "zh-hk"]
        XCTAssertEqual(languages, expectedResult, "Should be filtered down to wiki language codes")
        let header = Configuration.acceptLanguageHeader(with: languages)
        XCTAssertEqual(header, "zh-cn, zh-sg;q=0.8, zh-mo;q=0.6, zh-tw;q=0.4, zh-hk;q=0.2", "Accept-language header value should be correct")
    }
    
    func testPCSHeaders() {
        let configuration = Configuration.productionConfiguration(with: ["en", "zh-hant", "sr-ec"])
        let zhHeaders = configuration.pageContentServiceHeaders(for: "zh")
        XCTAssertEqual(zhHeaders["Accept-Language"], "zh-hant", "Page content service headers should only contain a single accept language code until https://phabricator.wikimedia.org/T256491 is fixed")
        let srHeaders = configuration.pageContentServiceHeaders(for: "sr")
        XCTAssertEqual(srHeaders["Accept-Language"], "sr-ec", "Page content service headers should only contain a single accept language code until https://phabricator.wikimedia.org/T256491 is fixed")
        let enHeaders = configuration.pageContentServiceHeaders(for: "en")
        XCTAssertEqual(enHeaders["Accept-Language"], nil, "Page content service headers should only contain Accept-Language for languages with variants")
    }
}
