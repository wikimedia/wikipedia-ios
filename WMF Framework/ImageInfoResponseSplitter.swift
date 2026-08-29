import Foundation

/// Splits one batched `action=query&prop=imageinfo` response into per-title bodies.
///
/// The offline download fetches image metadata in batches to keep it from making one
/// `api.php` request per image, but the gallery reads it back one title at a time and
/// the permanent cache is keyed by the literal request URL
/// (`PermanentlyPersistableURLCache.imageInfoItemKeyForURL`). So each page of a batched
/// response has to be stored under the single-title URL the gallery will later ask for.
enum ImageInfoResponseSplitter {

    enum SplitError: Error {
        /// The response had no `query.pages` to split.
        case malformedResponse
    }

    struct SplitResult {
        /// Body to store, keyed by the requested title it belongs to.
        let bodiesByRequestedTitle: [String: Data]
        /// Requested titles the response carried no page for — a deleted or renamed
        /// file, or a title the API did not recognise.
        let missingTitles: [String]
    }

    /// Header fields that describe the batch and would be wrong against a single title.
    ///
    /// `Etag` is read back to populate `If-None-Match`
    /// (`PermanentlyPersistableURLCache.urlRequestFromURL`), so storing the batch's
    /// validator against a single-title URL would send the server a validator
    /// belonging to a different resource. `Content-Length` describes the batch body.
    private static let droppedHeaderFields = ["etag", "content-length"]

    /// The batch response's headers, minus the ones that only make sense for the batch.
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

    /// Rebuilds one single-title response body per requested title.
    ///
    /// Each body keeps the `{"query": {"pages": {<pageid>: <page>}}}` shape that
    /// `MWKImageInfoFetcher.responseObjectForJSON:` reads, so the read path is
    /// unchanged.
    static func split(response: [String: Any], requestedTitles: [String]) throws -> SplitResult {
        guard let query = response["query"] as? [String: Any],
              let pages = query["pages"] as? [String: Any] else {
            throw SplitError.malformedResponse
        }

        // The API normalises titles (underscores to spaces, first-letter case) and
        // reports what it did in `query.normalized`, so a returned page's title often
        // is not the string we asked for.
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

    /// Underscores and spaces are interchangeable in MediaWiki titles, and the
    /// response echoes whichever form it prefers, so compare on one of them.
    private static func canonicalised(_ title: String) -> String {
        title.replacingOccurrences(of: "_", with: " ").precomposedStringWithCanonicalMapping
    }
}
