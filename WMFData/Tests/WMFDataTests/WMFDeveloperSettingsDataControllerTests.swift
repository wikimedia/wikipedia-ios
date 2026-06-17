import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFDeveloperSettingsDataControllerTests {

    private let fixture = WMFDataTestFixture()

    @Test
    func fetchFeatureConfigAndLoad() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDeveloperSettingsDataController()

            try await controller.fetchFeatureConfig()

            let config = try #require(controller.loadFeatureConfig())
            let yirConfig = try #require(config.common.yir(year: 2025))

            #expect(yirConfig.year == 2025)
            #expect(yirConfig.activeStartDateString == "2025-12-01T00:00:00Z")
            #expect(yirConfig.activeEndDateString == "2026-02-01T00:00:00Z")
            #expect(yirConfig.dataStartDateString == "2025-01-01T00:00:00Z")
            #expect(yirConfig.dataEndDateString == "2025-12-01T00:00:00Z")
            #expect(yirConfig.languages == 300)
            #expect(yirConfig.articles == 10000000)
            #expect(yirConfig.savedArticlesApps == 37574993)
            #expect(yirConfig.viewsApps == 1000000000)
            #expect(yirConfig.editsApps == 124356)
            #expect(yirConfig.editsPerMinute == 342)
            #expect(yirConfig.averageArticlesReadPerYear == 335)
            #expect(yirConfig.edits == 81987181)
            #expect(yirConfig.editsEN == 31000000)
            #expect(yirConfig.bytesAddedEN == 1000000000)
            #expect(yirConfig.hoursReadEN == 2423171000)
            #expect(yirConfig.yearsReadEN == 275000)
            #expect(yirConfig.topReadEN.count == 5)
            #expect(yirConfig.topReadPercentages.count == 8)
            #expect(yirConfig.hideCountryCodes.count == 22)
            #expect(yirConfig.hideDonateCountryCodes.count == 30)
        }
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.basicService = WMFFeatureConfigRequestMockService()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
    }
}

private final class WMFFeatureConfigRequestMockService: WMFService {
    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        guard isFeatureConfigRequest(request) else {
            completion(.failure(WMFServiceError.unexpectedResponse))
            return
        }

        WMFMockBasicService(jsonResourceName: "feature-get-config").performDecodableGET(request: request, completion: completion)
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.unexpectedResponse))
    }

    func clearCachedData() {}

    private func isFeatureConfigRequest(_ request: WMFServiceRequest) -> Bool {
        request.method == .GET &&
            (isProductionFeatureConfigRequest(request) || isStagingFeatureConfigRequest(request))
    }

    private func isProductionFeatureConfigRequest(_ request: WMFServiceRequest) -> Bool {
        request.url?.host == "en.wikipedia.org" &&
            request.url?.path == "/api/rest_v1/feed/configuration"
    }

    private func isStagingFeatureConfigRequest(_ request: WMFServiceRequest) -> Bool {
        guard let url = request.url,
              url.host == "test.wikipedia.org",
              url.path == "/wiki/MediaWiki:AppsFeatureConfig.json",
              let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return false
        }

        return queryItems.contains(URLQueryItem(name: "action", value: "raw"))
    }
}

private extension WMFDeveloperSettingsDataController {
    func fetchFeatureConfig() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            fetchFeatureConfig { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }
}
