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
            #expect(config.ios.visualEditorEnabled == true)
            #expect(controller.isVisualEditorEnabled)
        }
    }

    @Test
    func visualEditorIsDisabledWithoutAFeatureConfig() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            let controller = WMFDeveloperSettingsDataController()

            #expect(controller.loadFeatureConfig() == nil)
            #expect(controller.isVisualEditorEnabled == false)
        }
    }

    @Test
    func visualEditorIsDisabledWhenTheFeatureConfigOmitsTheKey() throws {
        let json = Data("""
        {"commonv1": {"yir": []}, "iosv1": {}}
        """.utf8)

        let config = try JSONDecoder().decode(WMFFeatureConfigResponse.self, from: json)

        #expect(config.ios.visualEditorEnabled == nil)
        #expect(config.ios.hCaptcha == nil)
    }

    @Test
    func useTestWikiDonateConfigsSwitchesTheDonateConfigsEnvironment() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            let controller = WMFDeveloperSettingsDataController.shared

            #expect(controller.donateConfigsServiceEnvironment == WMFDataEnvironment.current.serviceEnvironment)

            controller.useTestWikiDonateConfigs = true

            #expect(controller.donateConfigsServiceEnvironment == .staging)
            #expect(URL.donateConfigURL(environment: controller.donateConfigsServiceEnvironment)?.host == "test.wikipedia.org")
            #expect(URL.fundraisingCampaignConfigURL(environment: controller.donateConfigsServiceEnvironment)?.host == "test.wikipedia.org")
        }
    }

    @Test
    func useTestWikiDonateConfigsRoutesTheConfigFetches() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs = true
            requestRecordingService.requestedURLs = []

            WMFFundraisingCampaignDataController.shared.fetchConfig(countryCode: "NL", currentDate: Date()) { _ in }
            WMFDonateDataController.shared.fetchConfigs(for: "NL") { _ in }

            let hosts = requestRecordingService.requestedURLs.compactMap { $0.host }
            #expect(hosts.contains("test.wikipedia.org"))
            #expect(hosts.filter { $0 == "test.wikipedia.org" }.count == 2)
            #expect(hosts.contains("payments.wikimedia.org"))
            #expect(hosts.contains("donate.wikimedia.org") == false)

            WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs = false
            requestRecordingService.requestedURLs = []

            WMFFundraisingCampaignDataController.shared.fetchConfig(countryCode: "NL", currentDate: Date()) { _ in }
            WMFDonateDataController.shared.fetchConfigs(for: "NL") { _ in }

            let productionHosts = requestRecordingService.requestedURLs.compactMap { $0.host }
            #expect(productionHosts.filter { $0 == "donate.wikimedia.org" }.count == 2)
            #expect(productionHosts.contains("test.wikipedia.org") == false)
        }
    }

    @Test
    func togglingUseTestWikiDonateConfigsRefetchesTheCampaignConfig() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs = true

            let campaignConfigURLs = requestRecordingService.requestedURLs.filter { $0.path == "/wiki/MediaWiki:AppsCampaignConfig.json" }
            #expect(campaignConfigURLs.count == 1)
            #expect(campaignConfigURLs.first?.host == "test.wikipedia.org")

            requestRecordingService.requestedURLs = []
            WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs = false

            let productionCampaignConfigURLs = requestRecordingService.requestedURLs.filter { $0.path == "/wiki/MediaWiki:AppsCampaignConfig.json" }
            #expect(productionCampaignConfigURLs.count == 1)
            #expect(productionCampaignConfigURLs.first?.host == "donate.wikimedia.org")
        }
    }

    @Test
    func togglingUseTestWikiDonateConfigsClearsTheCachedConfigs() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            let sharedCacheStore = WMFDataEnvironment.current.sharedCacheStore
            try? sharedCacheStore?.save(key: "Donor Experience", "AppsCampaignConfig", value: "cached")
            try? sharedCacheStore?.save(key: "Donor Experience", "AppsDonationConfig", value: "cached")
            try? sharedCacheStore?.save(key: "Donor Experience", "PaymentMethods", value: "cached")

            WMFDeveloperSettingsDataController.shared.useTestWikiDonateConfigs = true

            let campaignConfig: String? = try? sharedCacheStore?.load(key: "Donor Experience", "AppsCampaignConfig")
            let donateConfig: String? = try? sharedCacheStore?.load(key: "Donor Experience", "AppsDonationConfig")
            let paymentMethods: String? = try? sharedCacheStore?.load(key: "Donor Experience", "PaymentMethods")
            #expect(campaignConfig == nil)
            #expect(donateConfig == nil)
            #expect(paymentMethods == nil)
        }
    }

    @Test
    func forceYiREntryPoint2026FetchesTheTestWikiFeatureConfigInProduction() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            // A new instance, so that it uses the recording service of this environment.
            let controller = WMFDeveloperSettingsDataController()

            controller.forceYiREntryPoint2026 = true

            let testWikiURLs = requestRecordingService.requestedURLs.filter { $0.path == "/wiki/MediaWiki:AppsFeatureConfig.json" }
            #expect(testWikiURLs.count == 1)
            #expect(testWikiURLs.first?.host == "test.wikipedia.org")

            requestRecordingService.requestedURLs = []
            controller.fetchFeatureConfig { _ in }

            let hosts = requestRecordingService.requestedURLs.compactMap { $0.host }
            #expect(hosts.contains("test.wikipedia.org"))
            #expect(hosts.contains("en.wikipedia.org"))
        }
    }

    @Test
    func withoutForceYiREntryPoint2026TheTestWikiFeatureConfigIsNotFetched() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            let controller = WMFDeveloperSettingsDataController()

            controller.forceYiREntryPoint2026 = false
            controller.fetchFeatureConfig { _ in }

            let hosts = requestRecordingService.requestedURLs.compactMap { $0.host }
            #expect(hosts.contains("test.wikipedia.org") == false)
            #expect(controller.loadTestWikiFeatureConfig() == nil)
        }
    }

    @Test
    func testWikiFeatureConfigIsStoredSeparately() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let controller = WMFDeveloperSettingsDataController()
            WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 = true

            controller.fetchTestWikiFeatureConfigIfNeeded()

            let testWikiConfig = try #require(controller.loadTestWikiFeatureConfig())
            #expect(testWikiConfig.common.yir(year: 2025) != nil)
            #expect(controller.loadFeatureConfig() == nil)
        }
    }

    @Test
    func testWikiFeatureConfigPostsTheBadgeNotificationOnTheMainThread() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureBackgroundCompletionEnvironment) {
            // Turn the flag on in the store directly. The setter posts its own notification on the calling thread.
            try WMFDataEnvironment.current.userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsForceYiREntryPoint2026.rawValue, value: true)
            let controller = WMFDeveloperSettingsDataController()

            let postedOnMainThread = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
                let observation = NotificationObservation()
                observation.token = NotificationCenter.default.addObserver(forName: WMFNSNotification.yearInReviewActivityTabBadgeNeedsUpdate, object: nil, queue: nil) { _ in
                    observation.finish { continuation.resume(returning: Thread.isMainThread) }
                }
                controller.fetchTestWikiFeatureConfigIfNeeded()
            }

            #expect(postedOnMainThread)
        }
    }

    @Test
    func forceYiREntryPoint2026SkipsOnlyTheStartDate() async {
        await fixture.withConfiguredEnvironment(configure: configureRequestRecordingEnvironment) {
            let dateFormatter = DateFormatter.mediaWikiAPIDateFormatter
            let common = WMFFeatureConfigResponse.Common.YearInReview.testConfig
            let config = WMFFeatureConfigResponse.Common.YearInReview(year: 2026, activeStartDateString: "2026-12-02T20:00:00Z", activeEndDateString: "2027-02-01T00:00:00Z", dataStartDateString: common.dataStartDateString, dataEndDateString: common.dataEndDateString, languages: common.languages, articles: common.articles, savedArticlesApps: common.savedArticlesApps, viewsApps: common.viewsApps, editsApps: common.editsApps, editsPerMinute: common.editsPerMinute, averageArticlesReadPerYear: common.averageArticlesReadPerYear, edits: common.edits, editsEN: common.editsEN, hoursReadEN: common.hoursReadEN, yearsReadEN: common.yearsReadEN, topReadEN: common.topReadEN, topReadPercentages: common.topReadPercentages, bytesAddedEN: common.bytesAddedEN, hideCountryCodes: common.hideCountryCodes, hideDonateCountryCodes: common.hideDonateCountryCodes)
            let beforeStart = dateFormatter.date(from: "2026-10-01T00:00:00Z")!
            let afterEnd = dateFormatter.date(from: "2027-02-01T00:00:01Z")!

            WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 = false
            #expect(config.isActive(for: beforeStart) == false)

            WMFDeveloperSettingsDataController.shared.forceYiREntryPoint2026 = true
            #expect(config.isActive(for: beforeStart))
            #expect(config.isActive(for: afterEnd) == false)
        }
    }

    private let requestRecordingService = WMFRequestRecordingMockService()

    private func configureRequestRecordingEnvironment() async {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.basicService = requestRecordingService
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        WMFDataEnvironment.current.serviceEnvironment = .production
    }

    private func configureBackgroundCompletionEnvironment() async {
        WMFDataEnvironment.current.basicService = WMFBackgroundCompletionMockService(wrapping: WMFFeatureConfigRequestMockService())
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.serviceEnvironment = .production
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
    }

    private func configureEnvironment() async {
        WMFDataEnvironment.current.basicService = WMFFeatureConfigRequestMockService()
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.serviceEnvironment = .production
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

private final class WMFRequestRecordingMockService: WMFService {

    private enum RecordingError: Error {
        case stubbedFailure
    }

    var requestedURLs: [URL] = []

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        record(request)
        completion(.failure(RecordingError.stubbedFailure))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        record(request)
        completion(.failure(RecordingError.stubbedFailure))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        record(request)
        completion(.failure(RecordingError.stubbedFailure))
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        record(request)
        completion(.failure(RecordingError.stubbedFailure))
    }

    func clearCachedData() {}

    private func record<R: WMFServiceRequest>(_ request: R) {
        if let url = request.url {
            requestedURLs.append(url)
        }
    }
}

/// Calls each completion on a background queue, as `WMFBasicService` does with URLSession.
private final class WMFBackgroundCompletionMockService: WMFService, @unchecked Sendable {
    private let wrapped: WMFService

    init(wrapping wrapped: WMFService) {
        self.wrapped = wrapped
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        wrapped.perform(request: request) { result in DispatchQueue.global().async { completion(result) } }
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        wrapped.perform(request: request) { result in DispatchQueue.global().async { completion(result) } }
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        wrapped.performDecodableGET(request: request) { (result: Result<T, Error>) in DispatchQueue.global().async { completion(result) } }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        wrapped.performDecodablePOST(request: request) { (result: Result<T, Error>) in DispatchQueue.global().async { completion(result) } }
    }

    func clearCachedData() {}
}

/// Removes the observer after the first notification, and runs the finish closure only once.
private final class NotificationObservation: @unchecked Sendable {
    var token: NSObjectProtocol?
    private let lock = NSLock()
    private var isFinished = false

    func finish(_ body: () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard !isFinished else { return }
        isFinished = true
        if let token { NotificationCenter.default.removeObserver(token) }
        body()
    }
}
