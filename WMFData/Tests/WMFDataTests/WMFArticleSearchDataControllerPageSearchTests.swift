import XCTest

@testable import WMFData
@testable import WMFDataMocks

/// Tests for the page search and nearby search of `WMFArticleSearchDataController`.
final class WMFArticleSearchDataControllerPageSearchTests: XCTestCase {

    private let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func controller(fixture: String) -> WMFArticleSearchDataController {
        WMFArticleSearchDataController(basicService: WMFMockBasicService(jsonResourceName: fixture))
    }

    // MARK: - Page search

    func testSearchPagesDecodesResultsInIndexOrder() async throws {
        let response = try await controller(fixture: "article-search-prefix-get").searchPages(term: "Barack", project: enProject, limit: 6, fullText: false)

        XCTAssertEqual(response.results.count, 6)
        XCTAssertEqual(response.results.map(\.index), [1, 2, 3, 4, 5, 6])
        XCTAssertEqual(response.results.first?.title, "Barack Obama")
        XCTAssertEqual(response.suggestion, "barracks")
    }

    func testSearchPagesDecodesFields() async throws {
        let response = try await controller(fixture: "article-search-prefix-get").searchPages(term: "Barack", project: enProject, limit: 6, fullText: false)
        let first = response.results[0]

        XCTAssertEqual(first.pageID, 534366)
        XCTAssertEqual(first.namespace, 0)
        XCTAssertTrue(first.isMainNamespace)
        XCTAssertEqual(first.description, "President of the United States from 2009 to 2017")
        XCTAssertEqual(first.revisionID, 1372672213)
        XCTAssertEqual(first.displayTitle, "<span class=\"mw-page-title-main\">Barack Obama</span>", "The display title comes from pageprops")
        XCTAssertEqual(first.thumbnail?.width, 320)
        XCTAssertEqual(first.thumbnailURL?.host, "upload.wikimedia.org")
        XCTAssertNil(first.coordinate)
        XCTAssertNil(first.extract)
    }

    func testSearchPagesDecodesCoordinateWithKilometerDimension() async throws {
        let response = try await controller(fixture: "article-search-prefix-get").searchPages(term: "Barack", project: enProject, limit: 6, fullText: false)
        let coordinate = response.results.first { $0.title == "Barack Obama Sr." }?.coordinate

        XCTAssertEqual(coordinate?.latitude, 41.878)
        XCTAssertEqual(coordinate?.longitude, -87.6298)
        XCTAssertEqual(coordinate?.type, "landmark")
        XCTAssertEqual(coordinate?.dimension, 2000)
        XCTAssertNil(coordinate?.distance)
    }

    func testSearchPagesDecodesRedirects() async throws {
        let response = try await controller(fixture: "article-search-prefix-get").searchPages(term: "Barack", project: enProject, limit: 6, fullText: false)

        XCTAssertEqual(response.redirects, [WMFArticleSearchRedirect(from: "Barack Hussein Obama", to: "Barack Obama")])
    }

    func testSearchPagesWithoutResultsReturnsSuggestion() async throws {
        let response = try await controller(fixture: "article-search-empty-get").searchPages(term: "asad", project: enProject, limit: 6, fullText: false)

        XCTAssertTrue(response.results.isEmpty)
        XCTAssertTrue(response.redirects.isEmpty)
        XCTAssertEqual(response.suggestion, "azad")
    }

    func testSearchPagesAcceptsCommons() async throws {
        let response = try await controller(fixture: "article-search-prefix-get").searchPages(term: "Barack", project: .commons, namespace: 6, limit: 6, fullText: true)
        XCTAssertEqual(response.results.count, 6)
    }

    func testSearchPagesRejectsWikidata() async {
        do {
            _ = try await controller(fixture: "article-search-prefix-get").searchPages(term: "Barack", project: .wikidata, limit: 6, fullText: false)
            XCTFail("Expected an error")
        } catch {
            guard case WMFDataControllerError.unsupportedProject = error else {
                return XCTFail("Unexpected error: \(error)")
            }
        }
    }

    // MARK: - Nearby search

    func testSearchNearbySortsByDistance() async throws {
        let results = try await controller(fixture: "article-search-nearby-get").searchNearby(project: enProject, latitude: 48.8566, longitude: 2.3522, radius: 1000, limit: 5)

        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results.map { $0.coordinate?.distance }, [0, 2.2, 7.6, 7.6, 11.1])
        XCTAssertEqual(results.last?.title, "Paris")
    }

    func testSearchNearbyDecodesExtractAndDimension() async throws {
        let results = try await controller(fixture: "article-search-nearby-get").searchNearby(project: enProject, latitude: 48.8566, longitude: 2.3522, radius: 1000, limit: 5)
        let paris = results.first { $0.title == "Paris" }

        XCTAssertEqual(paris?.coordinate?.dimension, 10000)
        XCTAssertEqual(paris?.coordinate?.type, "city")
        XCTAssertEqual(paris?.extract?.hasPrefix("Paris is the capital"), true)
        XCTAssertEqual(paris?.extract?.hasSuffix("..."), false, "The API ellipsis is removed")
    }

    // MARK: - The distance parameter

    /// The full text branch must ask for the distance. Without the parameter the API gives no
    /// distance, thus every result reports zero metres and the sort order is wrong.
    func testNearbyFullTextSearchAsksForTheDistance() async throws {
        let service = CapturingSearchService()
        let controller = WMFArticleSearchDataController(basicService: service)

        _ = try await controller.searchNearby(project: enProject, latitude: 48.8566, longitude: 2.3522, radius: 1000, term: "cafe", limit: 5)

        let parameters = try XCTUnwrap(service.capturedParameters.first)
        XCTAssertEqual(parameters["generator"] as? String, "search", "A search term uses the full text branch")
        XCTAssertEqual(parameters["codistancefrompoint"] as? String, "48.856600|2.352200")
    }

    func testNearbyGeoSearchAsksForTheDistance() async throws {
        let service = CapturingSearchService()
        let controller = WMFArticleSearchDataController(basicService: service)

        _ = try await controller.searchNearby(project: enProject, latitude: 48.8566, longitude: 2.3522, radius: 1000, limit: 5)

        let parameters = try XCTUnwrap(service.capturedParameters.first)
        XCTAssertEqual(parameters["generator"] as? String, "geosearch")
        XCTAssertEqual(parameters["codistancefrompoint"] as? String, "48.856600|2.352200")
    }

    // MARK: - Helpers

    func testDimensionParsing() {
        XCTAssertEqual(WMFArticleSearchCoordinate.meters(fromDimension: "1000"), 1000)
        XCTAssertEqual(WMFArticleSearchCoordinate.meters(fromDimension: "2km"), 2000)
        XCTAssertEqual(WMFArticleSearchCoordinate.meters(fromDimension: "500m"), 500)
        XCTAssertNil(WMFArticleSearchCoordinate.meters(fromDimension: "0"))
        XCTAssertNil(WMFArticleSearchCoordinate.meters(fromDimension: "abc"))
    }

    func testExtractCleaning() {
        XCTAssertEqual(WMFArticleSearchResult.cleanExtract("A cat..."), "A cat")
        XCTAssertEqual(WMFArticleSearchResult.cleanExtract("A cat."), "A cat.")
        XCTAssertNil(WMFArticleSearchResult.cleanExtract("..."))
        XCTAssertNil(WMFArticleSearchResult.cleanExtract(nil))
    }
}

/// Records the parameters of each request and answers with one fixture.
private final class CapturingSearchService: WMFService, @unchecked Sendable {
    private let data: Data
    private(set) var capturedParameters: [[String: Any]] = []

    /// The tests assert the request parameters, thus an empty result is enough.
    init(json: String = "{\"query\":{\"pages\":[]}}") {
        data = Data(json.utf8)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<Data, Error>) -> Void) {
        capturedParameters.append(request.parameters ?? [:])
        completion(.success(data))
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping (Result<[String: Any]?, Error>) -> Void) {
        capturedParameters.append(request.parameters ?? [:])
        completion(.success(try? JSONSerialization.jsonObject(with: data) as? [String: Any]))
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable>(request: R, completion: @escaping (Result<T, Error>) -> Void) {
        capturedParameters.append(request.parameters ?? [:])
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
