import Foundation
import WMFComponents

extension WMFContentGroup {
    
    @objc(detailViewControllerForPreviewItemAtIndex:dataStore:theme:source:)
    public func detailViewControllerForPreviewItemAtIndex(_ index: Int, dataStore: MWKDataStore, theme: Theme, source: ArticleSource) -> UIViewController? {
        detailViewControllerForPreviewItemAtIndex(index, dataStore: dataStore, theme: theme, source: source, imageRecDelegate: nil, imageRecLoggingDelegate: nil)
    }
	
    public func detailViewControllerForPreviewItemAtIndex(_ index: Int, dataStore: MWKDataStore, theme: Theme, source: ArticleSource, imageRecDelegate: WMFImageRecommendationsDelegate?, imageRecLoggingDelegate: WMFImageRecommendationsLoggingDelegate?) -> UIViewController? {
        switch detailType {
        case .page:
            guard let articleURL = previewArticleURLForItemAtIndex(index) else {
                return nil
            }
            return ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source)
        case .pageWithRandomButton:
            guard let articleURL = previewArticleURLForItemAtIndex(index) else {
                return nil
            }
            return RandomArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme, source: source)
        case .gallery:
            guard let date = self.date else {
                return nil
            }
            return WMFPOTDImageGalleryViewController(dates: [date], theme: theme, overlayViewTopBarHidden: false)
        case .story, .event:
            return detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: nil, imageRecLoggingDelegate: nil)
        case .suggestedEdits:
            return detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: imageRecDelegate, imageRecLoggingDelegate: imageRecLoggingDelegate)
        default:
            return nil
        }
    }
    
    @objc(detailViewControllerWithDataStore:theme:)
    public func detailViewControllerWithDataStore(_ dataStore: MWKDataStore, theme: Theme) -> UIViewController? {
        return detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: nil, imageRecLoggingDelegate: nil)
    }
    
    public func detailViewControllerWithDataStore(_ dataStore: MWKDataStore, theme: Theme, imageRecDelegate: WMFImageRecommendationsDelegate?, imageRecLoggingDelegate: WMFImageRecommendationsLoggingDelegate?) -> UIViewController? {
        var vc: UIViewController? = nil
        switch moreType {
        case .pageList:
            guard let articleURLs = contentURLs else {
                break
            }
            vc = ArticleURLListViewController(articleURLs: articleURLs, dataStore: dataStore, contentGroup: self, theme: theme)
            vc?.title = moreTitle
        case .pageListWithLocation:
            guard let articleURLs = contentURLs else {
                break
            }
            vc = ArticleLocationCollectionViewController(articleURLs: articleURLs, dataStore: dataStore, contentGroup: self, theme: theme, needsCloseButton: true, source: .undefined)
        case .news:
            guard let stories = fullContent?.object as? [WMFFeedNewsStory] else {
                break
            }
            vc = NewsViewController(stories: stories, dataStore: dataStore, contentGroup: self, theme: theme)
        case .onThisDay:
            guard let date = midnightUTCDate, let events = fullContent?.object as? [WMFFeedOnThisDayEvent] else {
                break
            }
            vc = OnThisDayViewController(events: events, dataStore: dataStore, midnightUTCDate: date, contentGroup: self, theme: theme)
        case .pageWithRandomButton:
            guard let siteURL = siteURL else {
                break
            }
            let firstRandom = WMFFirstRandomViewController(siteURL: siteURL, dataStore: dataStore, theme: theme)
            (firstRandom as Themeable).apply(theme: theme)
            vc = firstRandom
        case .imageRecommendations:
            vc = WMFImageRecommendationsViewController.imageRecommendationsViewController(dataStore: dataStore, imageRecDelegate: imageRecDelegate, imageRecLoggingDelegate: imageRecLoggingDelegate)
        default:
            break
        }
        
        if let customVC = vc as? ColumnarCollectionViewController {
            customVC.headerTitle = headerTitle
            customVC.footerButtonTitle = WMFLocalizedString("explore-detail-back-button-title", value: "Back to Explore feed", comment: "Title for button that allows users to exit detail view and return to Explore.")
            customVC.headerSubtitle = moreType != .onThisDay ? headerSubTitle : nil
            customVC.removeTopHeaderSpacing = true
        }
        
        return vc
    }
}

