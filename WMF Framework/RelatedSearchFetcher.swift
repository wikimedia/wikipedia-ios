import Foundation

@objc(WMFRelatedSearchFetcher)
final class RelatedSearchFetcher: Fetcher {

    @objc func fetchRelatedArticles(forArticleWithURL articleURL: URL?, completion: @escaping (Error?, [WMFInMemoryURLKey: RelatedPage]?) -> Void) {
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
            "format": "json",
            "inprop": "varianttitles"
        ]

        performDecodableMediaWikiAPIGET(for: articleURL, with: queryParams) { (result: Result<RelatedResponse, Error>) in
            switch result {
            case .success(let result):
                guard let relatedPages = self.getRelatedPages(from: result, siteURL: siteURL), relatedPages.count > 0 else {
                    return
                }

                let relatedPagesWithUniqueURLKeys: [(WMFInMemoryURLKey, RelatedPage)] = relatedPages.compactMap { (summary) -> (WMFInMemoryURLKey, RelatedPage)? in

                    if let variant = articleURL.wmf_languageVariantCode {
                        summary.languageVariantCode = variant
                    }

                    guard let articleKey = summary.key else {
                        return nil
                    }
                    return (articleKey, summary)
                }
                completion(nil, Dictionary(uniqueKeysWithValues: relatedPagesWithUniqueURLKeys))

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
            let variantTitles = getVariantTitles(page.varianttitles)
            let firstVariantTitle = variantTitles?.first?.title

            var pageTitle = page.title
            if let firstVariantTitle {
                pageTitle = firstVariantTitle
            }
            let item = RelatedPage(pageId: page.pageid, ns: page.ns, title: pageTitle, index: page.index, thumbnail: page.thumbnail, articleDescription: page.description, descriptionSource: page.descriptionsource, contentModel: page.contentmodel, pageLanguage: page.pagelanguage, pageLanguageHtmlCode: page.pagelanguagehtmlcode, pageLanguageDir: page.pagelanguagedir, touched: page.touched, lastRevId: page.lastrevid, length: page.length)
            item.articleURL = getArticleURLFromTitle(title: pageTitle, siteURL: siteURL)
            pages.append(item)
        }
        return pages
    }

    private func getVariantTitles(_ variantTitles: [String: String]?) -> [VariantTitle]? {

        var languageTitles: [VariantTitle] = []

        guard let variantTitles else { return nil }

        for (variant, title) in variantTitles {
            let languageTitle = VariantTitle(variant: variant, title: title)
            languageTitles.append(languageTitle)
        }

        return languageTitles
    }

    private struct VariantTitle {
        let variant: String
        let title: String
    }

}
