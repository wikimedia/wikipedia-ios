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

extension Array where Element == URLRequest {
    /// Whether a request asks for each page's title in every language variant (prop=info, inprop=varianttitles)
    func containsVariantTitlesRequest(generator: String) -> Bool {
        contains { request in
            guard let url = request.url,
                  let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems,
                  let prop = queryItems.first(where: { $0.name == "prop" })?.value else {
                return false
            }

            return queryItems.contains(URLQueryItem(name: "generator", value: generator)) &&
                prop.split(separator: "|").contains("info") &&
                queryItems.contains(URLQueryItem(name: "inprop", value: "varianttitles"))
        }
    }
}
