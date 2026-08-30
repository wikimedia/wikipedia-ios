import Foundation

/// Splits one batched `action=query&prop=imageinfo` response into per-title bodies.
///
/// The gallery reads image metadata back one title at a time and the permanent cache is keyed by the
/// literal request URL, so each page of a batched response is stored under its single-title URL.
enum ImageInfoResponseSplitter {

    enum SplitError: Error {
        case malformedResponse
    }

    struct SplitResult {
        let bodiesByRequestedTitle: [String: Data]
        let missingTitles: [String]
    }

    // Etag is read back into If-None-Match and belongs to the batch URL; Content-Length describes the batch body
    private static let droppedHeaderFields = ["etag", "content-length"]

    static func perTitleHeaderFields(from response: HTTPURLResponse?) -> [String: String] {
        guard let response = response else {
            return [:]
        }

        var fields: [String: String] = [:]
        for (rawKey, rawValue) in response.allHeaderFields {
            guard let key = rawKey as? String, let value = rawValue as? String else {
                continue
            }
            guard !droppedHeaderFields.contains(key.lowercased()) else {
                continue
            }
            fields[key] = value
        }
        return fields
    }

    /// Rebuilds one single-title body per requested title, keeping the shape responseObjectForJSON: reads.
    static func split(response: [String: Any], requestedTitles: [String]) throws -> SplitResult {
        guard let query = response["query"] as? [String: Any],
              let pages = query["pages"] as? [String: Any] else {
            throw SplitError.malformedResponse
        }

        // note, the API normalises titles and reports what it did in query.normalized, so a returned page's title often isn't what we asked for
        var normalisedByRequested: [String: String] = [:]
        if let normalized = query["normalized"] as? [[String: Any]] {
            for entry in normalized {
                guard let from = entry["from"] as? String, let to = entry["to"] as? String else {
                    continue
                }
                normalisedByRequested[canonicalised(from)] = to
            }
        }

        var pagesByTitle: [String: (pageID: String, page: Any)] = [:]
        for (pageID, page) in pages {
            guard let page = page as? [String: Any], let title = page["title"] as? String else {
                continue
            }
            pagesByTitle[canonicalised(title)] = (pageID, page)
        }

        var bodies: [String: Data] = [:]
        var missing: [String] = []

        for requestedTitle in requestedTitles {
            let canonicalRequested = canonicalised(requestedTitle)
            let lookup = normalisedByRequested[canonicalRequested].map(canonicalised) ?? canonicalRequested

            guard let match = pagesByTitle[lookup] else {
                missing.append(requestedTitle)
                continue
            }

            let body: [String: Any] = ["query": ["pages": [match.pageID: match.page]]]
            guard JSONSerialization.isValidJSONObject(body),
                  let data = try? JSONSerialization.data(withJSONObject: body) else {
                missing.append(requestedTitle)
                continue
            }

            bodies[requestedTitle] = data
        }

        return SplitResult(bodiesByRequestedTitle: bodies, missingTitles: missing)
    }

    // underscores and spaces are interchangeable in MediaWiki titles, so compare on one of them
    private static func canonicalised(_ title: String) -> String {
        title.replacingOccurrences(of: "_", with: " ").precomposedStringWithCanonicalMapping
    }
}
