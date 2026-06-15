import Foundation

/// URL protocol used by `SearchHTTPClient` to satisfy completion-handler based
/// data tasks from in-memory response data.
final class SearchURLProtocol: URLProtocol, @unchecked Sendable {
    private static let responseDataKey = "SearchURLProtocol.responseData"

    /// Ephemeral configuration that routes only requests tagged by
    /// `request(_:withResponseData:)` through this protocol.
    static var configuration: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SearchURLProtocol.self]
        return configuration
    }

    /// Tags a request with response data so `canInit(with:)` accepts it and
    /// `startLoading()` can replay the bytes back to the client.
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
