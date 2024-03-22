import Foundation
import Components

extension WMFContentGroup {
	@objc(detailViewControllerForPreviewItemAtIndex:dataStore:theme:)
    public func detailViewControllerForPreviewItemAtIndex(_ index: Int, dataStore: MWKDataStore, theme: Theme) -> UIViewController? {
        switch detailType {
        case .page:
            guard let articleURL = previewArticleURLForItemAtIndex(index) else {
                return nil
            }
            return ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        case .pageWithRandomButton:
            guard let articleURL = previewArticleURLForItemAtIndex(index) else {
                return nil
            }
            return RandomArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        case .gallery:
            guard let date = self.date else {
                return nil
            }
            return WMFPOTDImageGalleryViewController(dates: [date], theme: theme, overlayViewTopBarHidden: false)
        case .story, .event:
            return detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: nil)
        default:
            return nil
        }
    }
    
    @objc(detailViewControllerWithDataStore:theme:)
    public func detailViewControllerWithDataStore(_ dataStore: MWKDataStore, theme: Theme) -> UIViewController? {
        return detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: nil)
    }
    
    public func detailViewControllerWithDataStore(_ dataStore: MWKDataStore, theme: Theme, imageRecDelegate: WKImageRecommendationsDelegate?) -> UIViewController? {
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
            vc = ArticleLocationCollectionViewController(articleURLs: articleURLs, dataStore: dataStore, contentGroup: self, theme: theme)
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
            
            guard let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
                  let project = WikimediaProject(siteURL: siteURL)?.wkProject,
                  let imageRecDelegate = imageRecDelegate else {
                return nil
            }

            let surveyLocalizedStrings = WKImageRecommendationsViewModel.LocalizedStrings.SurveyLocalizedStrings(
                reason: WMFLocalizedString("image-rec-survey-title", value: "Reason", comment: "Title of the image recommendations survey view. Displayed in the navigation bar as title of view."),
                cancel: CommonStrings.cancelActionTitle,
                submit: WMFLocalizedString("image-rec-survey-submit-button", value: "Submit", comment: "Title of the image recommendations survey view submit button."),
                improveSuggestions: WMFLocalizedString("image-rec-survey-instructions-1", value: "Your answers improve future suggestions.", comment: "Instructions displayed on the image recommendations survey view."),
                selectOptions: WMFLocalizedString("image-rec-survey-instructions-2", value: "Select one or more options", comment: "Instructions displayed on the image recommendations survey view."),
                imageNotRelevant: WMFLocalizedString("image-rec-survey-option-1", value: "Image is not relevant", comment: "Title of available option displayed on the image recommendations survey view."),
                notEnoughInformation: WMFLocalizedString("image-rec-survey-option-2", value: "Not enough information to decide", comment: "Title of available option displayed on the image recommendations survey view."),
                imageIsOffensive: WMFLocalizedString("image-rec-survey-option-3", value: "Image is offensive", comment: "Title of available option displayed on the image recommendations survey view."),
                imageIsLowQuality: WMFLocalizedString("image-rec-survey-option-4", value: "Image is low quality", comment: "Title of available option displayed on the image recommendations survey view."),
                dontKnowSubject: WMFLocalizedString("image-rec-survey-option-5", value: "I don’t know this subject", comment: "Title of available option displayed on the image recommendations survey view."),
                other: WMFLocalizedString("image-rec-survey-option-6", value: "Other", comment: "Title of available option displayed on the image recommendations survey view.")
            )

            let title = WMFLocalizedString("image-rec-title", value: "Add image", comment: "Title of the image recommendation view. Displayed in the navigation bar above an article summary.")
            let viewArticle = WMFLocalizedString("image-rec-view-article", value: "View article", comment: "Button from an image recommendation article summary. Tapping the button displays the full article.")
            let localizedStrings = WKImageRecommendationsViewModel.LocalizedStrings(title: title, viewArticle: viewArticle, surveyLocalizedStrings: surveyLocalizedStrings)
            let viewModel = WKImageRecommendationsViewModel(project: project, localizedStrings: localizedStrings)
            let imageRecommendationsViewController = WKImageRecommendationsViewController(viewModel: viewModel, delegate: imageRecDelegate)
            return imageRecommendationsViewController
        default:
            break
        }
        if let customVC = vc as? ViewController {
            customVC.navigationMode = .detail
        }
        if let customVC = vc as? ColumnarCollectionViewController {
            customVC.headerTitle = headerTitle
            customVC.footerButtonTitle = WMFLocalizedString("explore-detail-back-button-title", value: "Back to Explore feed", comment: "Title for button that allows users to exit detail view and return to Explore.")
            customVC.headerSubtitle = moreType != .onThisDay ? headerSubTitle : nil
        }
        return vc
    }
}
