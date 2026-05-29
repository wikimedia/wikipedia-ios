import Foundation
@testable import WMF

/// Test double for `SessionHTTPClient` that lets search fetcher tests inject a
/// JSON response and inspect the outgoing requests without touching the network.
final class SearchHTTPClient: SessionHTTPClient {
    /// Data returned to the fetcher for every supported request path.
    var responseData = Data()

    /// Requests issued by `WMFSearchFetcher`, used to verify the expected API
    /// query was made.
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

/// Supplies the same `SearchHTTPClient` instance to the legacy `Session`
/// initializer so tests can read the requests it captured.
struct SearchHTTPClientProvider: SessionHTTPClientProvider {
    let httpClient: SearchHTTPClient

    func httpClient(defaultURLSession: URLSession, sessionDelegate: SessionDelegate) -> SessionHTTPClient {
        httpClient
    }
}
