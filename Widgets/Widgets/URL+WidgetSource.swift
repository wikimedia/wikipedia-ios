import Foundation

extension Optional where Wrapped == URL {
    /// Returns a URL with `source=widget` appended to its query, preserving existing query items.
    func wmf_urlWithWidgetSource() -> URL? {
        guard let url = self else { return nil }
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return url }
        var queryItems = components.queryItems ?? []
        // If a source already exists, do not overwrite
        if !queryItems.contains(where: { $0.name == "source" }) {
            queryItems.append(URLQueryItem(name: "source", value: "widget"))
        }
        components.queryItems = queryItems
        return components.url ?? url
    }
}

extension URL {
    func wmf_urlWithWidgetSource() -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        var queryItems = components.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "source" }) {
            queryItems.append(URLQueryItem(name: "source", value: "widget"))
        }
        components.queryItems = queryItems
        return components.url ?? self
    }
}

/// Convenience free functions to avoid extension visibility issues in some compilation contexts
func wmf_urlWithWidgetSource(_ url: URL?) -> URL? {
    guard let url = url else { return nil }
    return url.wmf_urlWithWidgetSource()
}

func wmf_urlWithWidgetSource(_ url: URL) -> URL {
    return url.wmf_urlWithWidgetSource()
}
