import Foundation

extension WMFContentGroup {
    var contentURLs: [URL]? {
        switch contentType {
        case .topReadPreview:
            guard let previews = fullContent?.object as? [WMFFeedTopReadArticlePreview] else {
                return nil
            }
            return previews.compactMap { $0.articleURL }
        case .story:
            guard let stories = fullContent?.object as? [WMFFeedNewsStory] else {
                return nil
            }
            return stories.compactMap { $0.featuredArticlePreview?.articleURL ?? $0.articlePreviews?.first?.articleURL }
        case .URL:
            return fullContent?.object as? [URL]
        default:
            return nil
        }
    }
    
    @objc(detailViewControllerWithDataStore:theme:)
    public func detailViewControllerWithDataStore(_ dataStore: MWKDataStore, theme: Theme) -> UIViewController? {
        switch moreType {
        case .pageList:
            guard let articleURLs = contentURLs else {
                return nil
            }
            let vc = ArticleURLListViewController(articleURLs: articleURLs, dataStore: dataStore, contentGroup: self, theme: theme)
            vc.title = moreTitle
            return vc
        case .pageListWithLocation:
            guard let articleURLs = contentURLs else {
                return nil
            }
            return ArticleLocationCollectionViewController(articleURLs: articleURLs, dataStore: dataStore, theme: theme)
        case .news:
            guard let stories = fullContent?.object as? [WMFFeedNewsStory] else {
                return nil
            }
            return NewsViewController(stories: stories, dataStore: dataStore, theme: theme)
        case .onThisDay:
            guard let date = midnightUTCDate, let events = fullContent?.object as? [WMFFeedOnThisDayEvent] else {
                return nil
            }
            return OnThisDayViewController(events: events, dataStore: dataStore, midnightUTCDate: date, theme: theme)
        case .pageWithRandomButton:
            guard let siteURL = siteURL else {
                return nil
            }
            return WMFFirstRandomViewController(siteURL: siteURL, dataStore: dataStore, theme: theme)
        default:
            return nil
        }
    }
}
