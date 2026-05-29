import Foundation
@testable import Wikipedia
@testable import WMF
import XCTest

final class WMFSearchFetcherTests: XCTestCase {
    private var fetcher: WMFSearchFetcher!
    private var httpClient: SearchHTTPClient!

    override func setUp() {
        super.setUp()

        httpClient = SearchHTTPClient()
        let session = Session(configuration: .current, httpClientProvider: SearchHTTPClientProvider(httpClient: httpClient))
        fetcher = WMFSearchFetcher(session: session, configuration: .current)
    }

    override func tearDown() {
        fetcher.cancelAllFetches()
        fetcher = nil
        httpClient = nil

        super.tearDown()
    }

    func testNonEmptyPrefixResponse() throws {
        let json = try jsonFixture(named: "BarackSearch")
        httpClient.responseData = try JSONSerialization.data(withJSONObject: json)
        let siteURL = try XCTUnwrap(URL(string: "https://en.wikipedia.org"))

        let expectation = expectation(description: "Wait for articles")

        fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15, failure: { error in
            XCTFail("Expected search success, got \(error)")
            expectation.fulfill()
        }, success: { result in
            let query = json["query"] as? [String: Any]
            let pages = query?["pages"] as? [String: Any]
            XCTAssertEqual(result.results?.count, pages?.count)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10)
        XCTAssertTrue(httpClient.capturedRequests.containsPrefixSearchRequest)
    }

    func testEmptyPrefixResponse() throws {
        let json = try jsonFixture(named: "NoSearchResultsWithSuggestion")
        httpClient.responseData = try JSONSerialization.data(withJSONObject: json)
        let siteURL = try XCTUnwrap(URL(string: "https://en.wikipedia.org"))

        let expectation = expectation(description: "Wait for articles")

        fetcher.fetchArticles(forSearchTerm: "foo", siteURL: siteURL, resultLimit: 15, failure: { error in
            XCTFail("Expected search success, got \(error)")
            expectation.fulfill()
        }, success: { result in
            let query = json["query"] as? [String: Any]
            let searchInfo = query?["searchinfo"] as? [String: Any]
            XCTAssertEqual(result.searchSuggestion, searchInfo?["suggestion"] as? String)
            XCTAssertEqual(result.results?.count, 0)
            expectation.fulfill()
        })

        waitForExpectations(timeout: 10)
        XCTAssertTrue(httpClient.capturedRequests.containsPrefixSearchRequest)
    }

    private func jsonFixture(named name: String) throws -> [String: Any] {
        let data = try XCTUnwrap(wmf_bundle().wmf_data(fromContentsOfFile: name, ofType: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}

private final class SearchHTTPClient: SessionHTTPClient {
    var responseData = Data()
    var capturedRequests: [URLRequest] = []
    private lazy var urlSession = URLSession(configuration: SearchURLProtocol.configuration)

    func dataTask(with request: URLRequest, callback: Session.Callback) -> URLSessionTask {
        fatalError("Callback data tasks are not used by WMFSearchFetcherTests")
    }

    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        capturedRequests.append(request)

        let fixtureRequest = SearchURLProtocol.request(request, withResponseData: responseData)
        return urlSession.dataTask(with: fixtureRequest, completionHandler: completionHandler)
    }

    func downloadTask(with url: URL, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Download tasks are not used by WMFSearchFetcherTests")
    }

    func downloadTask(with request: URLRequest, completionHandler: @escaping (URL?, URLResponse?, Error?) -> Void) -> URLSessionDownloadTask {
        fatalError("Download tasks are not used by WMFSearchFetcherTests")
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        capturedRequests.append(request)
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else {
            throw URLError(.badURL)
        }

        return (responseData, response)
    }

    func invalidateAndCancel() {
        urlSession.invalidateAndCancel()
    }
}

private struct SearchHTTPClientProvider: SessionHTTPClientProvider {
    let httpClient: SearchHTTPClient

    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        httpClient
    }
}

private final class SearchURLProtocol: URLProtocol, @unchecked Sendable {
    private static let responseDataKey = "SearchURLProtocol.responseData"

    static var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SearchURLProtocol.self]
        return configuration
    }

    static func request(_ request: URLRequest, withResponseData data: Data) -> URLRequest {
        guard let mutableRequest = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
            preconditionFailure("URLRequest should bridge to NSMutableURLRequest")
        }

        URLProtocol.setProperty(data, forKey: responseDataKey, in: mutableRequest)
        return mutableRequest as URLRequest
    }

    override static func canInit(with request: URLRequest) -> Bool {
        URLProtocol.property(forKey: responseDataKey, in: request) != nil
    }

    override static func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }

        let data = URLProtocol.property(forKey: Self.responseDataKey, in: request) as? Data ?? Data()
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {
    }
}

private extension Array where Element == URLRequest {
    var containsPrefixSearchRequest: Bool {
        contains { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return false
            }

            return queryItems.contains(URLQueryItem(name: "generator", value: "prefixsearch")) &&
                queryItems.contains(URLQueryItem(name: "gpssearch", value: "foo"))
        }
    }
}
