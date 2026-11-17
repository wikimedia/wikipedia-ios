import Foundation

extension Array where Element == URLRequest {
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

    var containsFullTextSearchRequest: Bool {
        contains { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                  let queryItems = components.queryItems else {
                return false
            }

            return queryItems.contains(URLQueryItem(name: "generator", value: "search"))
        }
    }
}

extension URLRequest {
    /// The query parameters of the request, by name.
    var queryParameters: [String: String] {
        guard let url,
              let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems else {
            return [:]
        }
        return Dictionary(queryItems.map { ($0.name, $0.value ?? "") }, uniquingKeysWith: { _, last in last })
    }
}
