import Foundation
import Testing
@testable import WMFData

struct WMFUserImpactDataControllerTests {

    private static let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    // MARK: - Error paths

    @Test
    func fetchThrowsWhenServiceUnavailable() async throws {
        let controller = WMFUserImpactDataController(service: nil)

        await #expect(throws: WMFDataControllerError.basicServiceUnavailable) {
            _ = try await controller.fetch(userID: 1, project: Self.project, language: "en")
        }
    }

    @Test
    func fetchThrowsUnexpectedResponseWhenDataIsNil() async throws {
        let service = MockImpactService()
        service.result = .success(nil)
        let controller = WMFUserImpactDataController(service: service)

        let thrown = await capturedError {
            _ = try await controller.fetch(userID: 1, project: Self.project, language: "en")
        }

        guard let error = thrown as? WMFDataControllerError, case .unexpectedResponse = error else {
            Issue.record("Expected .unexpectedResponse, got \(String(describing: thrown))")
            return
        }
    }

    @Test
    func fetchWrapsServiceFailureAsServiceError() async throws {
        let service = MockImpactService()
        service.result = .failure(WMFServiceError.invalidHttpResponse(500))
        let controller = WMFUserImpactDataController(service: service)

        let thrown = await capturedError {
            _ = try await controller.fetch(userID: 1, project: Self.project, language: "en")
        }

        guard let error = thrown as? WMFDataControllerError, case .serviceError = error else {
            Issue.record("Expected .serviceError, got \(String(describing: thrown))")
            return
        }
    }

    // MARK: - Success parsing

    @Test
    func fetchParsesFullResponse() async throws {
        let service = MockImpactService()
        service.result = .success([
            "totalPageviewsCount": 1234,
            "totalEditsCount": 56,
            "receivedThanksCount": 7,
            "lastEditTimestamp": TimeInterval(1_700_000_000),
            "longestEditingStreak": ["datePeriod": ["days": 9]],
            "editCountByDay": ["2026-01-15": 3, "2026-01-16": 2],
            "dailyTotalViews": ["2026-01-15": 100, "2026-01-16": 50],
            "topViewedArticles": [
                "Article A": ["viewsCount": 200, "views": ["2026-01-15": 120, "2026-01-16": 80]],
                "Article B": ["viewsCount": 30, "views": ["2026-01-15": 30]]
            ]
        ])
        let controller = WMFUserImpactDataController(service: service)

        let impact = try await controller.fetch(userID: 42, project: Self.project, language: "en")

        #expect(impact.totalPageviewsCount == 1234)
        #expect(impact.totalEditsCount == 56)
        #expect(impact.receivedThanksCount == 7)
        #expect(impact.longestEditingStreak == 9)
        #expect(impact.lastEditTimestamp == Date(timeIntervalSince1970: 1_700_000_000))

        // Assert on counts/sums rather than specific Date keys to stay timezone-independent.
        #expect(impact.editCountByDay.count == 2)
        #expect(impact.editCountByDay.values.reduce(0, +) == 5)
        #expect(impact.dailyTotalViews.count == 2)
        #expect(impact.dailyTotalViews.values.reduce(0, +) == 150)

        #expect(impact.topViewedArticles.count == 2)
        let articleA = try #require(impact.topViewedArticles.first { $0.title == "Article A" })
        #expect(articleA.viewsCount == 200)
        #expect(articleA.views.count == 2)
        #expect(articleA.views.values.reduce(0, +) == 200)
    }

    @Test
    func fetchHandlesMissingOptionalFields() async throws {
        let service = MockImpactService()
        // Only a single field present; everything else absent.
        service.result = .success(["totalEditsCount": 12])
        let controller = WMFUserImpactDataController(service: service)

        let impact = try await controller.fetch(userID: 1, project: Self.project, language: "en")

        #expect(impact.totalEditsCount == 12)
        #expect(impact.totalPageviewsCount == nil)
        #expect(impact.receivedThanksCount == nil)
        #expect(impact.longestEditingStreak == nil)
        #expect(impact.lastEditTimestamp == nil)
        #expect(impact.topViewedArticles.isEmpty)
        #expect(impact.editCountByDay.isEmpty)
        #expect(impact.dailyTotalViews.isEmpty)
    }

    @Test
    func fetchSkipsTopViewedArticlesMissingRequiredFields() async throws {
        let service = MockImpactService()
        service.result = .success([
            "topViewedArticles": [
                "Valid": ["viewsCount": 10, "views": ["2026-01-15": 10]],
                "MissingViews": ["viewsCount": 5],
                "MissingViewsCount": ["views": ["2026-01-15": 3]]
            ]
        ])
        let controller = WMFUserImpactDataController(service: service)

        let impact = try await controller.fetch(userID: 1, project: Self.project, language: "en")

        // Only the entry with both "views" and "viewsCount" is kept.
        #expect(impact.topViewedArticles.count == 1)
        #expect(impact.topViewedArticles.first?.title == "Valid")
    }

    // MARK: - Helpers

    private func capturedError(_ body: () async throws -> Void) async -> Error? {
        do {
            try await body()
            return nil
        } catch {
            return error
        }
    }
}

/// Minimal `WMFService` mock returning a caller-configured `[String: Any]?` result synchronously.
/// `WMFUserImpactDataController` only uses the dictionary-returning `perform` overload.
private final class MockImpactService: WMFService {
    var result: Result<[String: Any]?, Error> = .success(nil)

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        completion(result)
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        completion(.failure(WMFServiceError.missingData))
    }

    func clearCachedData() {}
}
