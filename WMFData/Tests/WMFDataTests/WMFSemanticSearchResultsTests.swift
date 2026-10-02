import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFData
@testable import WMFDataMocks

@Suite(.serialized)
final class WMFSemanticSearchResultsTests {

    private let fixture = WMFDataTestFixture()
    private let controller = WMFSemanticSearchDataController.shared
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "fr", languageVariantCode: nil))

    @Test
    func resultsKeepTheRankOrderOfTheAPI() async throws {
        try await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockBasicService()) }) {
            let response = try await controller.fetchResults(query: "qu'est-ce que la communication", project: project)

            #expect(response.results.map(\.title) == ["Complexité de la communication", "Communication", "Communication animale"])
        }
    }

    @Test
    func resultsComeFromOneRequestOfEight() async throws {
        let service = WMFRecordingService()
        try await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: service) }) {
            _ = try await controller.fetchResults(query: "communication", project: project)

            #expect(service.requests.count == 1)
            let request = try #require(service.requests.first)
            #expect(request.method == .GET)
            #expect(request.parameters?["gsrlimit"] as? String == "8")
            #expect(request.parameters?["gsroffset"] == nil)
        }
    }

    @Test
    func resultsDecodeSnippetSectionAndThumbnail() async throws {
        try await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockBasicService()) }) {
            let response = try await controller.fetchResults(query: "qu'est-ce que la communication", project: project)

            let first = try #require(response.results.first)
            #expect(first.pageID == 7825418)
            #expect(first.snippetHTML.hasPrefix("<span class=\"searchmatch\">La complexité de la communication"))
            #expect(first.sectionTitle == nil)
            #expect(first.thumbnailURL == nil)

            let last = try #require(response.results.last)
            #expect(last.sectionTitle == "Différence entre communication et information")
            #expect(last.thumbnailURL?.host == "thumb.wikimedia.org")
        }
    }

    @Test
    func rateLimitStatusBecomesRateLimited() async throws {
        _ = await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockFailingService(statusCode: 429)) }) {
            await #expect(throws: WMFSemanticSearchDataController.SearchError.rateLimited) {
                try await controller.fetchResults(query: "communication", project: project)
            }
        }
    }

    @Test
    func serverErrorStatusBecomesBackendUnavailable() async throws {
        _ = await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockFailingService(statusCode: 503)) }) {
            await #expect(throws: WMFSemanticSearchDataController.SearchError.backendUnavailable) {
                try await controller.fetchResults(query: "communication", project: project)
            }
        }
    }

    @Test
    func apiErrorInTheBodyBecomesBackendUnavailable() async throws {
        _ = await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockBasicService(jsonResourceName: "semantic-search-get-error")) }) {
            await #expect(throws: WMFSemanticSearchDataController.SearchError.backendUnavailable) {
                try await controller.fetchResults(query: "communication", project: project)
            }
        }
    }

    @Test
    func missingServiceThrows() async throws {
        _ = await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: nil) }) {
            await #expect(throws: WMFDataControllerError.basicServiceUnavailable) {
                try await controller.fetchResults(query: "communication", project: project)
            }
        }
    }

    @Test
    func attributionDecodesTheTrustSignals() async throws {
        try await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockBasicService()) }) {
            let attribution = try await controller.fetchAttribution(title: "Communication", project: project)

            #expect(attribution.contributorCount == nil)
            #expect(attribution.referenceCount == 2)
            #expect(attribution.lastUpdated == DateFormatter.mediaWikiAPIDateFormatter.date(from: "2026-09-03T06:29:36Z"))
        }
    }

    @Test
    func attributionNeedsATitle() async throws {
        _ = await fixture.withConfiguredEnvironment(configure: { self.configureEnvironment(service: WMFMockBasicService()) }) {
            await #expect(throws: WMFDataControllerError.failureCreatingRequestURL) {
                try await controller.fetchAttribution(title: "", project: project)
            }
        }
    }

    private func configureEnvironment(service: WMFService?) {
        WMFDataEnvironment.current.basicService = service
    }
}

/// Answers with the semantic search fixture and keeps every request it receives.
private final class WMFRecordingService: WMFService {

    struct Request {
        let method: WMFServiceRequestMethod
        let parameters: [String: Any]?
    }

    private let fixtureService = WMFMockBasicService()
    private(set) var requests: [Request] = []

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        record(request)
        fixtureService.perform(request: request, completion: completion)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        record(request)
        fixtureService.perform(request: request, completion: completion)
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        record(request)
        fixtureService.performDecodableGET(request: request, completion: completion)
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        record(request)
        fixtureService.performDecodablePOST(request: request, completion: completion)
    }

    func clearCachedData() {}

    private func record<R: WMFServiceRequest>(_ request: R) {
        requests.append(Request(method: request.method, parameters: request.parameters))
    }
}

private final class WMFMockFailingService: WMFService {

    private let statusCode: Int

    init(statusCode: Int) {
        self.statusCode = statusCode
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, any Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.invalidHttpResponse(statusCode)))
    }

    func clearCachedData() {}
}
