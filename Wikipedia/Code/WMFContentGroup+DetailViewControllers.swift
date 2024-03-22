import Foundation
import Components

extension WMFContentGroup {
    
    @objc(detailViewControllerForPreviewItemAtIndex:dataStore:theme:)
    public func detailViewControllerForPreviewItemAtIndex(_ index: Int, dataStore: MWKDataStore, theme: Theme) -> UIViewController? {
        detailViewControllerForPreviewItemAtIndex(index, dataStore: dataStore, theme: theme, imageRecDelegate: nil)
    }
	
    public func detailViewControllerForPreviewItemAtIndex(_ index: Int, dataStore: MWKDataStore, theme: Theme, imageRecDelegate: WKImageRecommendationsDelegate?) -> UIViewController? {
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
        case .suggestedEdits:
            return detailViewControllerWithDataStore(dataStore, theme: theme, imageRecDelegate: imageRecDelegate)
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
            
            guard let appLanguage = dataStore.languageLinkController.appLanguage,
                  let project = WikimediaProject(siteURL: appLanguage.siteURL)?.wkProject,
                  let imageRecDelegate = imageRecDelegate else {
                return nil
            }
            
            let contentLanguageCode = appLanguage.contentLanguageCode
            let semanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: contentLanguageCode)
            
            let title = WMFLocalizedString("image-rec-title", value: "Add image", comment: "Title of the image recommendation view. Displayed in the navigation bar above an article summary.")
            let viewArticle = WMFLocalizedString("image-rec-view-article", value: "View article", comment: "Button from an image recommendation article summary. Tapping the button displays the full article.")

            let onboardingStrings = WKImageRecommendationsViewModel.LocalizedStrings.OnboardingStrings(
                title: WMFLocalizedString("image-rec-onboarding-title", value: "Add an image to an article", comment: "Title of onboarding view displayed when user first visits image recommendations feature view."),
                firstItemTitle: WMFLocalizedString("image-rec-onboarding-item-1-title", value: "View a suggestion", comment: "Title of first item in onboarding view displayed when user first visits image recommendations feature view."),
                firstItemBody: WMFLocalizedString("image-rec-onboarding-item-1-body", value: "Decide if a suggested image should be placed in a Wikipedia article.", comment: "Body of first item in onboarding view displayed when user first visits image recommendations feature view."),
                secondItemTitle: WMFLocalizedString("image-rec-onboarding-item-2-title", value: "Accept or reject an image", comment: "Title of second item in onboarding view displayed when user first visits image recommendations feature view."),
                secondItemBody: WMFLocalizedString("image-rec-onboarding-item-2-body", value: "Suggestions are machine generated and you will use your judgment to decide whether to accept or reject them.", comment: "Body of second item in onboarding view displayed when user first visits image recommendations feature view."),
                thirdItemTitle: WMFLocalizedString("image-rec-onboarding-item-3-title", value: "Licensed images", comment: "Title of third item in onboarding view displayed when user first visits image recommendations feature view."),
                thirdItemBody: WMFLocalizedString("image-rec-onboarding-item-3-body", value: "Images are from Wikimedia Commons, a collection of freely licensed images used by Wikipedia.", comment: "Body of third item in onboarding view displayed when user first visits image recommendations feature view."),
                continueButton: CommonStrings.continueButton,
                learnMoreButton: WMFLocalizedString("image-rec-onboarding-learn-more-button", value: "Learn about add an image", comment: "Title of learn more button in onboarding view displayed when user first visits image recommendations feature view.")
            )

            let localizedStrings = WKImageRecommendationsViewModel.LocalizedStrings(title: CommonStrings.addImageTitle, viewArticle: CommonStrings.viewArticle, onboardingStrings: onboardingStrings, bottomSheetTitle: CommonStrings.bottomSheetTitle, yesButtonTitle: CommonStrings.yesButtonTitle, noButtonTitle: CommonStrings.noButtonTitle, notSureButtonTitle: CommonStrings.notSureButtonTitle)

            let viewModel = WKImageRecommendationsViewModel(project: project, semanticContentAttribute: semanticContentAttribute, localizedStrings: localizedStrings)
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

