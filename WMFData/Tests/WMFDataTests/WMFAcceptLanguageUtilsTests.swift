import XCTest
@testable import WMFData

final class WMFAcceptLanguageUtilsTests: XCTestCase {

    func testTraditionalChineseTaiwanSendsLegacyCodeFirst() {
        XCTAssertEqual(WMFAcceptLanguageUtils.acceptLanguageHeaderValue(forLanguageVariantCode: "zh-Hant-TW"), "zh-tw,zh-Hant-TW;q=0.9")
    }

    func testSimplifiedChineseMainlandSendsLegacyCodeFirst() {
        XCTAssertEqual(WMFAcceptLanguageUtils.acceptLanguageHeaderValue(forLanguageVariantCode: "zh-Hans-CN"), "zh-cn,zh-Hans-CN;q=0.9")
    }

    func testChineseScriptOnlyVariantSendsOnlyBCP47Code() {
        XCTAssertEqual(WMFAcceptLanguageUtils.acceptLanguageHeaderValue(forLanguageVariantCode: "zh-Hant"), "zh-Hant")
    }

    func testSerbianLatinSendsOnlyBCP47Code() {
        XCTAssertEqual(WMFAcceptLanguageUtils.acceptLanguageHeaderValue(forLanguageVariantCode: "sr-Latn"), "sr-Latn")
    }

    func testLanguageCodesWithoutVariantsAreUnchanged() {
        for languageCode in ["en", "de", "zh"] {
            XCTAssertEqual(WMFAcceptLanguageUtils.acceptLanguageHeaderValue(forLanguageVariantCode: languageCode), languageCode)
        }
    }
}
