import Foundation

@objc(WMFRelatedSearchFetcher)
final class RelatedSearchFetcher: Fetcher {

    @objc func fetchRelatedArticles(forArticleWithURL articleURL: URL?, completion: @escaping (Error?, [WMFInMemoryURLKey: ArticleSummary]?) -> Void) {
        guard
            let articleURL = articleURL,
            let articleTitle = articleURL.percentEncodedPageTitleForPathComponents,
            let siteURL = articleURL.wmf_site
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
            "format": "json"
        ]

        performDecodableMediaWikiAPIGET(for: articleURL, with: queryParams) { (result: Result<RelatedResponse, Error>) in
            switch result {
            case .success(let result):
                guard let relatedPages = self.getRelatedPages(from: result, siteURL: siteURL), relatedPages.count > 0 else {
                    return
                }
                
                let summaries = relatedPages.map { ArticleSummary(relatedPage: $0) }
                
                let summaryKeysWithValues: [(WMFInMemoryURLKey, ArticleSummary)] = summaries.compactMap { (summary) -> (WMFInMemoryURLKey, ArticleSummary)? in
                                summary.languageVariantCode = articleURL.wmf_languageVariantCode
                                guard let articleKey = summary.key else {
                                    return nil
                                }
                                return (articleKey, summary)
                        }
                
                completion(nil, Dictionary(uniqueKeysWithValues: summaryKeysWithValues))

            case .failure:
                completion(Fetcher.unexpectedResponseError, nil)
            }
        }

    }

    func getArticleURLFromTitle(title: String, siteURL: URL) -> URL? {
        return siteURL.wmf_URL(withTitle: title)
    }

    private func getRelatedPages(from response: RelatedResponse, siteURL: URL) -> [RelatedPage]? {

        var pages: [RelatedPage] = []

        guard let query = response.query else {
            return nil
        }

        for page in query.pages {
            let item = RelatedPage(pageId: page.pageid, ns: page.ns, title: page.title, index: page.index, thumbnail: page.thumbnail, articleDescription: page.description, descriptionSource: page.descriptionsource, contentModel: page.contentmodel, pageLanguage: page.pagelanguage, pageLanguageHtmlCode: page.pagelanguagehtmlcode, pageLanguageDir: page.pagelanguagedir, touched: page.touched, lastRevId: page.lastrevid, length: page.length)
            item.articleURL = getArticleURLFromTitle(title: page.title, siteURL: siteURL)
            item.languageVariantCode = siteURL.wmf_languageVariantCode
            pages.append(item)
        }
        return pages
    }

}

private extension ArticleSummary {
    convenience init(relatedPage: RelatedPage) {
        let namespace = ArticleSummary.Namespace(id: relatedPage.ns, text: nil)
        
        var thumbnail: ArticleSummaryImage?
        if let source = relatedPage.thumbnail?.source,
           let width = relatedPage.thumbnail?.width,
           let height = relatedPage.thumbnail?.height {
            thumbnail = ArticleSummaryImage(source: source, width: width, height: height)
        }
        let desktopURLs = ArticleSummaryURLs(page: relatedPage.articleURL?.absoluteString)

        self.init(id: Int64(relatedPage.pageId), wikidataID: nil, revision: nil, timestamp: relatedPage.touched, index: relatedPage.index, namespace: namespace, title: relatedPage.title, displayTitle: relatedPage.title, articleDescription: relatedPage.articleDescription, extract: nil, extractHTML: nil, thumbnail: thumbnail, original: nil, coordinates: nil, languageVariantCode: relatedPage.languageVariantCode, contentURLs: ArticleSummaryContentURLs(desktop: desktopURLs, mobile: nil))
    }
}
