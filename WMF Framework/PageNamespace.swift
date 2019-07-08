// https://en.wikipedia.org/wiki/Wikipedia:Namespace
@objc public enum PageNamespace: Int {
    case main
    case talk
    case user
    case userTalk
    case project
    case projectTalk
    case file
    case fileTalk
}

extension PageNamespace {
    init?(namespaceValue: Int?) {
        guard let rawValue = namespaceValue else {
            return nil
        }
        self.init(rawValue: rawValue)
    }
}

extension WMFArticle {
    public var pageNamespace: PageNamespace? {
        return PageNamespace(namespaceValue: ns?.intValue)
    }
}

extension MWKSearchResult {
    public var pageNamespace: PageNamespace? {
        return PageNamespace(namespaceValue: titleNamespace?.intValue)
    }
}

@objc(WMFPageInfoFetcher)
public final class PageInfoFetcher: Fetcher {
    private struct PageInfo: Decodable {
        let query: Query?

        struct Query: Decodable {
            let pages: [Page]?

            struct Page: Decodable {
                let ns: Int?
            }

            enum CodingKeys: String, CodingKey {
                case pages
            }

            init(from decoder: Decoder) throws {
                let values = try decoder.container(keyedBy: CodingKeys.self)
                let pages: Dictionary<String, Page> = try values.decode(Dictionary.self, forKey: .pages)
                self.pages = Array(pages.values)
            }
        }
    }

    @objc public func fetchNamespaceValueForArticle(with url: URL, completion: @escaping (NSNumber?) -> Void) {
        guard
            let language = url.wmf_language,
            let title = url.wmf_title,
            let url = configuration.mediaWikiAPIURLForWikiLanguage(language, with: ["action": "query", "format": "json", "titles": title]).url
        else {
            completion(nil)
            return
        }

        session.jsonDecodableTask(with: url) { (pageInfo: PageInfo?, response, error) in
            if let ns = pageInfo?.query?.pages?.first?.ns {
                completion(NSNumber(value: ns))
            } else {
                completion(nil)
            }
        }
    }
}
