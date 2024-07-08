import Foundation

@objc(WMFRelatedSearchFetcher)
final class RelatedSearchFetcher: Fetcher {
    private struct RelatedPages: Decodable {
        let pages: [ArticleSummary]?
    }

    @objc func fetchRelatedArticles(forArticleWithURL articleURL: URL?, completion: @escaping (Error?, [WMFInMemoryURLKey: ArticleSummary]?) -> Void) {
        guard
            let articleURL = articleURL,
            let articleTitle = articleURL.percentEncodedPageTitleForPathComponents
        else {
            completion(Fetcher.invalidParametersError, nil)
            return
        }

        let queryParams: [String: Any] = [
            "action": "query",
            "formatversion": 2,
            "generator": "search",
            "gsrlimit": 20,
            "gsrnamespace": 0,
            "gsrqiprofile": "classic_noboostlinks",
            "gsrsearch": "morelike:\(articleTitle)",
            "origin": "*",
            "pilimit": 20,
            "piprop": "thumbnail",
            "pithumbsize": 160,
            "prop": "pageimages|description|info",
            "format": "json",
            "inprop": "varianttitles"
        ]

        performDecodableMediaWikiAPIGET(for: articleURL, with: queryParams) { (result: Result<RelatedResponse, Error>) in
            switch result {
            case .success(let success):
                print(success)
            case .failure:
                completion(Fetcher.unexpectedResponseError, nil)
            }
        }

    }
}
