import Foundation

/// One route in the test fixture manifest.
struct TestNetworkFixture: Decodable {
    let method: String?
    let url: String?
    let ignoreQuery: Bool?
    let host: String?
    let path: String?
    let pathPrefix: String?
    let pathSuffix: String?
    let queryItems: [String: String]?
    let statusCode: Int?
    let headers: [String: String]?
    let body: String?
    let bodyBase64: String?
    let bodyResource: String?

    /// Matchers are combined with AND semantics. At least one URL matcher must
    /// be present so an empty manifest entry cannot become a catch-all route.
    func matches(_ request: URLRequest) -> Bool {
        guard let requestURL = request.url else {
            return false
        }

        if let method, method.uppercased() != (request.httpMethod ?? "GET").uppercased() {
            return false
        }

        if let url, !Self.url(url, ignoringQuery: ignoreQuery ?? false, matches: requestURL) {
            return false
        }

        if let host, host != requestURL.host {
            return false
        }

        if let path, path != requestURL.path {
            return false
        }

        if let pathPrefix, !requestURL.path.hasPrefix(pathPrefix) {
            return false
        }

        if let pathSuffix, !requestURL.path.hasSuffix(pathSuffix) {
            return false
        }

        if let queryItems, !Self.queryItems(queryItems, match: requestURL) {
            return false
        }

        return self.url != nil || host != nil || path != nil || pathPrefix != nil || pathSuffix != nil || queryItems != nil
    }

    private static func url(_ expectedURLString: String, ignoringQuery: Bool, matches actualURL: URL) -> Bool {
        guard let expectedURL = URL(string: expectedURLString) else {
            return false
        }

        guard ignoringQuery else {
            return expectedURL == actualURL
        }

        guard var expectedComponents = URLComponents(url: expectedURL, resolvingAgainstBaseURL: false),
              var actualComponents = URLComponents(url: actualURL, resolvingAgainstBaseURL: false) else {
            return false
        }

        expectedComponents.query = nil
        actualComponents.query = nil
        return expectedComponents.url == actualComponents.url
    }

    private static func queryItems(_ expectedItems: [String: String], match url: URL) -> Bool {
        guard !expectedItems.isEmpty,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let actualItems = components.queryItems else {
            return false
        }

        return expectedItems.allSatisfy { expectedName, expectedValue in
            actualItems.contains { actualItem in
                actualItem.name == expectedName && (actualItem.value ?? "") == expectedValue
            }
        }
    }
}
