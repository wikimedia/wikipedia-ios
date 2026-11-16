import Foundation

extension Optional where Wrapped == URL {
}

extension URL {
    func wmf_urlWithWidgetSource(name: String) -> URL {
        guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else { return self }
        var queryItems = components.queryItems ?? []
        if !queryItems.contains(where: { $0.name == "source" }) {
            queryItems.append(URLQueryItem(name: "source", value: "widget_\(name)"))
        }
        components.queryItems = queryItems
        return components.url ?? self
    }
}

/// Convenience free functions to avoid extension visibility issues in some compilation contexts
func wmf_urlWithWidgetSource(_ url: URL?, name: String) -> URL? {
    guard let url = url else { return nil }
    return url.wmf_urlWithWidgetSource(name: name)
}

func wmf_urlWithWidgetSource(_ url: URL, name: String) -> URL {
    return url.wmf_urlWithWidgetSource(name: name)
}
