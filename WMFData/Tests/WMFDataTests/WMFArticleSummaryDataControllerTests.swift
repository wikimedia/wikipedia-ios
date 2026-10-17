import XCTest

@testable import WMFData
@testable import WMFDataMocks

final class WMFArticleSummaryDataControllerTests: XCTestCase {

    // MARK: - Accept-Language

    /// Fetches a summary through a capturing session and returns the Accept-Language header it sent.
    /// Each call uses a unique title, since the shared controller caches summaries by page.
    private func acceptLanguageHeader(forLanguageCode languageCode: String, languageVariantCode: String?) async -> String? {
        let originalBasicService = WMFDataEnvironment.current.basicService
        defer {
            WMFDataEnvironment.current.basicService = originalBasicService
        }
        let urlSession = WMFMockNoInternetConnectionSession()
        WMFDataEnvironment.current.basicService = WMFBasicService(urlSession: urlSession)

        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        _ = try? await WMFArticleSummaryDataController.shared.fetchArticleSummary(project: project, title: "Accept-Language test \(UUID().uuidString)")
        return urlSession.request?.value(forHTTPHeaderField: "Accept-Language")
    }

    func testFetchSummarySendsLegacyCodeFirstForRegionalChineseVariant() async {
        let acceptLanguage = await acceptLanguageHeader(forLanguageCode: "zh", languageVariantCode: "zh-Hant-TW")
        XCTAssertEqual(acceptLanguage, "zh-tw,zh-Hant-TW;q=0.9")
    }

    func testFetchSummarySendsOnlyBCP47CodeForSerbianVariant() async {
        let acceptLanguage = await acceptLanguageHeader(forLanguageCode: "sr", languageVariantCode: "sr-Latn")
        XCTAssertEqual(acceptLanguage, "sr-Latn")
    }

    func testFetchSummaryKeepsTheDefaultAcceptLanguageForLanguagesWithoutVariants() async {
        let originalAcceptLanguageUtility = WMFDataEnvironment.current.acceptLanguageUtility
        defer {
            WMFDataEnvironment.current.acceptLanguageUtility = originalAcceptLanguageUtility
        }
        WMFDataEnvironment.current.acceptLanguageUtility = { "de-de, en-us;q=0.50" }

        for languageCode in ["en", "de"] {
            let acceptLanguage = await acceptLanguageHeader(forLanguageCode: languageCode, languageVariantCode: nil)
            XCTAssertEqual(acceptLanguage, "de-de, en-us;q=0.50", languageCode)
        }
    }
}
