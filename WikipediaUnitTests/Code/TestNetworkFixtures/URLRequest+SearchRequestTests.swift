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
}
