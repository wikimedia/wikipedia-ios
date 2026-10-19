import Foundation
import Testing
import WMFData
@testable import Wikipedia
@testable import WMF

struct WMFSearchFetcherTests {
    @Test
    func nonEmptyPrefixResponse() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "Barack", siteURL: siteURL, resultLimit: 15)

        let query = harness.json["query"] as? [String: Any]
        let pages = query?["pages"] as? [[String: Any]]
        #expect(result.results.count == pages?.count)
        #expect(result.results.first?.displayTitle == "Barack Obama")
        #expect(result.results.map { $0.index?.intValue } == [1, 2, 3, 4, 5, 6])
        #expect(result.redirectMappings.first?.redirectFromTitle == "Barack Hussein Obama")
        #expect(result.searchTerm == "Barack")
        #expect(harness.service.capturedParameters?["generator"] as? String == "prefixsearch")
    }

    @Test
    func emptyPrefixResponse() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchEmpty")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))

        let result = try await harness.fetcher.fetchArticles(forSearchTerm: "asad", siteURL: siteURL, resultLimit: 15)

        let query = harness.json["query"] as? [String: Any]
        let searchInfo = query?["searchinfo"] as? [String: Any]
        #expect(result.searchSuggestion == searchInfo?["suggestion"] as? String)
        #expect(result.results.isEmpty)
        #expect(harness.service.capturedParameters?["generator"] as? String == "prefixsearch")
    }

    @Test
    func fullTextResponseMergesIntoPreviousResults() async throws {
        let harness = try makeHarness(fixture: "ArticleSearchPrefix")
        defer {
            harness.fetcher.cancelAllFetches()
        }
        let siteURL = try #require(URL(string: "https://en.wikipedia.org"))
        let previous = try await harness.fetcher.fetchArticles(forSearchTerm: "Barack", siteURL: siteURL, resultLimit: 15)
        let previousCount = previous.results.count

        let merged = try await harness.fetcher.fetchArticles(forSearchTerm: "Barack", siteURL: siteURL, resultLimit: 15, fullTextSearch: true, appendToPreviousResults: previous)

        #expect(merged === previous)
        #expect(merged.results.count == previousCount, "Results with a known display title are not added twice")
        #expect(harness.service.capturedParameters?["generator"] as? String == "search")
    }

    // MARK: - Harness

    private struct Harness {
        let fetcher: WMFSearchFetcher
        let service: FixtureService
        let json: [String: Any]
    }

    private func makeHarness(fixture: String) throws -> Harness {
        let data = try #require(Bundle(for: WMFSearchFetcherTestBundleToken.self).wmf_data(fromContentsOfFile: fixture, ofType: "json"))
        let json = try #require(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let service = FixtureService(data: data)
        let fetcher = WMFSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service))
        return Harness(fetcher: fetcher, service: service, json: json)
    }
}

private final class WMFSearchFetcherTestBundleToken {}

/// A service that answers every request with one fixture.
private final class FixtureService: WMFService, @unchecked Sendable {
    private let data: Data
    private(set) var capturedParameters: [String: Any]?

    init(data: Data) {
        self.data = data
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        capturedParameters = request.parameters
        completion(.success(data))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        capturedParameters = request.parameters
        completion(.success(try? JSONSerialization.jsonObject(with: data) as? [String: Any]))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        capturedParameters = request.parameters
        do {
            completion(.success(try JSONDecoder().decode(T.self, from: data)))
        } catch {
            completion(.failure(error))
        }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        performDecodableGET(request: request, completion: completion)
    }

    func clearCachedData() {
    }
}

private extension WMFSearchFetcher {
    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt) async throws -> WMFSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, failure: { error in
                continuation.resume(throwing: error)
            }, success: { result in
                continuation.resume(returning: result)
            })
        }
    }

    func fetchArticles(forSearchTerm searchTerm: String, siteURL: URL, resultLimit: UInt, fullTextSearch: Bool, appendToPreviousResults previous: WMFSearchResults?) async throws -> WMFSearchResults {
        try await withCheckedThrowingContinuation { continuation in
            fetchArticles(forSearchTerm: searchTerm, siteURL: siteURL, resultLimit: resultLimit, fullTextSearch: fullTextSearch, appendToPreviousResults: previous, failure: { error in
                continuation.resume(throwing: error)
            }, success: { result in
                continuation.resume(returning: result)
            })
        }
    }
}
