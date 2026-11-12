import XCTest
import WMFData
@testable import WMF
@testable import Wikipedia

final class PageContentServiceHeadersTests: XCTestCase {
    private let configuration = Configuration.current

    private func headers(languageCode: String, languageVariantCode: String?) -> [String: String] {
        var url = URL(string: "https://\(languageCode).wikipedia.org/wiki/Test")!
        url.wmf_languageVariantCode = languageVariantCode
        return configuration.pageContentServiceHeaders(for: url)
    }

    func testTraditionalChineseTaiwanSendsLegacyCodeFirst() {
        XCTAssertEqual(headers(languageCode: "zh", languageVariantCode: "zh-Hant-TW"), ["Accept-Language": "zh-tw,zh-Hant-TW;q=0.9"])
    }

    func testLanguagesWithoutVariantsSendNoHeaders() {
        for languageCode in ["en", "de"] {
            XCTAssertEqual(headers(languageCode: languageCode, languageVariantCode: nil), [:], languageCode)
        }
    }

    func testFooterReadMoreOmitsLangCodeWithoutVariant() throws {
        let url = URL(string: "https://de.wikipedia.org/wiki/Berlin")!
        let readMore = PageContentService.Footer.ReadMore(itemCount: 3, apiBaseURL: "https://de.wikipedia.org/api/rest_v1/", langCode: url.wmf_legacyLanguageVariantCode)
        let json = try XCTUnwrap(String(data: PageContentService.paramsEncoder.encode(readMore), encoding: .utf8))
        XCTAssertFalse(json.contains("langCode"))
    }

    func testFooterReadMoreSendsLegacyLangCodeForVariant() throws {
        var url = URL(string: "https://zh.wikipedia.org/wiki/Linux")!
        url.wmf_languageVariantCode = "zh-Hant-TW"
        let readMore = PageContentService.Footer.ReadMore(itemCount: 3, apiBaseURL: "https://zh.wikipedia.org/api/rest_v1/", langCode: url.wmf_legacyLanguageVariantCode)
        let json = try XCTUnwrap(String(data: PageContentService.paramsEncoder.encode(readMore), encoding: .utf8))
        XCTAssertTrue(json.contains("\"langCode\":\"zh-tw\""))
    }

    func testChineseLegacyCodesMatchLanguageVariantsFile() throws {
        let chineseVariants = try XCTUnwrap(WikipediaLookup.allLanguageVariants).filter { $0.languageCode == "zh" }
        XCTAssertFalse(chineseVariants.isEmpty)
        for variant in chineseVariants {
            let acceptLanguage = WMFAcceptLanguageUtils.acceptLanguageHeaderValue(forLanguageVariantCode: variant.languageVariantCode)
            if variant.legacyLanguageVariantCode.caseInsensitiveCompare(variant.languageVariantCode) == .orderedSame {
                XCTAssertEqual(acceptLanguage, variant.languageVariantCode)
            } else {
                XCTAssertEqual(acceptLanguage, "\(variant.legacyLanguageVariantCode),\(variant.languageVariantCode);q=0.9")
            }
        }
    }

    func testLegacyLanguageVariantCode() {
        var url = URL(string: "https://zh.wikipedia.org/wiki/Test")!
        url.wmf_languageVariantCode = "zh-Hant-HK"
        XCTAssertEqual(url.wmf_legacyLanguageVariantCode, "zh-hk")

        url.wmf_languageVariantCode = nil
        XCTAssertNil(url.wmf_legacyLanguageVariantCode)
    }
}
