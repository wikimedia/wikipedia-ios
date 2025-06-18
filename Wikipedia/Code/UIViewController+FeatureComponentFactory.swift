import Foundation
import SwiftUI
import WMFComponents
import WMF
import WMFData

extension WMFImageRecommendationsViewController {
    static func imageRecommendationsViewController(dataStore: MWKDataStore, imageRecDelegate: WMFImageRecommendationsDelegate?, imageRecLoggingDelegate: WMFImageRecommendationsLoggingDelegate?) -> WMFImageRecommendationsViewController? {
        guard let appLanguage = dataStore.languageLinkController.appLanguage,
              let project = WikimediaProject(siteURL: appLanguage.siteURL)?.wmfProject,
              let imageRecDelegate,
              let imageRecLoggingDelegate else {
            return nil
        }

        let surveyLocalizedStrings = WMFImageRecommendationsViewModel.LocalizedStrings.SurveyLocalizedStrings(
            title: WMFLocalizedString("image-rec-survey-title", value: "Reason", comment: "Title of the image recommendations survey view. Displayed in the navigation bar as title of view."),
            cancel: CommonStrings.cancelActionTitle,
            submit: WMFLocalizedString("image-rec-survey-submit-button", value: "Submit", comment: "Title of the image recommendations survey view submit button."),
            subtitle: WMFLocalizedString("image-rec-survey-instructions-1", value: "Your answers improve future suggestions.", comment: "Instructions displayed on the image recommendations survey view."),
            instructions: WMFLocalizedString("image-rec-survey-instructions-2", value: "Select one or more options", comment: "Instructions displayed on the image recommendations survey view."),
            otherPlaceholder: WMFLocalizedString("image-rec-survey-option-6", value: "Other", comment: "Title of available option displayed on the image recommendations survey view.")
        )

        let contentLanguageCode = appLanguage.contentLanguageCode
        let semanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: contentLanguageCode)

        let onboardingStrings = WMFImageRecommendationsViewModel.LocalizedStrings.OnboardingStrings(
            title: WMFLocalizedString("image-rec-onboarding-title", value: "Add an image to an article", comment: "Title of onboarding view displayed when user first visits image recommendations feature view."),
            firstItemTitle: WMFLocalizedString("image-rec-onboarding-item-1-title", value: "View a suggestion", comment: "Title of first item in onboarding view displayed when user first visits image recommendations feature view."),
            firstItemBody: WMFLocalizedString("image-rec-onboarding-item-1-body", value: "Decide if a suggested image should be placed in a Wikipedia article.", comment: "Body of first item in onboarding view displayed when user first visits image recommendations feature view."),
            secondItemTitle: WMFLocalizedString("image-rec-onboarding-item-2-title", value: "Accept or reject an image", comment: "Title of second item in onboarding view displayed when user first visits image recommendations feature view."),
            secondItemBody: WMFLocalizedString("image-rec-onboarding-item-2-body", value: "Suggestions are machine generated and you will use your judgment to decide whether to accept or reject them.", comment: "Body of second item in onboarding view displayed when user first visits image recommendations feature view."),
            thirdItemTitle: WMFLocalizedString("image-rec-onboarding-item-3-title", value: "Licensed images", comment: "Title of third item in onboarding view displayed when user first visits image recommendations feature view."),
            thirdItemBody: WMFLocalizedString("image-rec-onboarding-item-3-body", value: "Images are from Wikimedia Commons, a collection of freely licensed images used by Wikipedia.", comment: "Body of third item in onboarding view displayed when user first visits image recommendations feature view."),
            continueButton: CommonStrings.continueButton,
            learnMoreButton: WMFLocalizedString("image-rec-onboarding-learn-more-button", value: "Learn more about suggested edits", comment: "Title of learn more button in onboarding view displayed when user first visits image recommendations feature view.")
        )
        
        let emptyStrings = WMFEmptyViewModel.LocalizedStrings(title: WMFLocalizedString("image-rec-empty-title", value: "You have no more suggested images available at this time.", comment: "Title of empty view displayed when there are no more image recommendations."), subtitle: WMFLocalizedString("image-rec-empty-subtitle", value: "Try coming back later.", comment: "Subtitle of empty view displayed when there are no more image recommendations."), titleFilter: nil, buttonTitle: nil, attributedFilterString: nil)
        
        let errorStrings = WMFErrorViewModel.LocalizedStrings(title: WMFLocalizedString("image-rec-error-title", value: "Unable to load page", comment: "Title of error view displayed when there was an issue when loading image recommendations."), subtitle: WMFLocalizedString("image-rec-error-subtitle", value: "Something went wrong.", comment: "Subtitle of error view displayed when there was an issue when loading image recommendations."), buttonTitle: CommonStrings.tryAgain)
        
        let firstTooltipStrings = WMFTooltipViewModel.LocalizedStrings(title: WMFLocalizedString("image-rec-tooltip-1-title", value: "Review", comment: "Title of first tooltip displayed when landing on image recommendations feature for the first time."), body: WMFLocalizedString("image-rec-tooltip-1-body", value: "Review this article to understand its topic.", comment: "Body of first tooltip displayed when landing on image recommendations feature for the first time."), buttonTitle: CommonStrings.nextTitle)
        
        let secondTooltipStrings = WMFTooltipViewModel.LocalizedStrings(title: WMFLocalizedString("image-rec-tooltip-2-title", value: "Inspect", comment: "Title of second tooltip displayed when landing on image recommendations feature for the first time."), body: WMFLocalizedString("image-rec-tooltip-2-body", value: "Inspect the image and its associated information.", comment: "Body of second tooltip displayed when landing on image recommendations feature for the first time."), buttonTitle: CommonStrings.nextTitle)
        
        let thirdTooltipStrings = WMFTooltipViewModel.LocalizedStrings(title: WMFLocalizedString("image-rec-tooltip-3-title", value: "Decide", comment: "Title of second tooltip displayed when landing on image recommendations feature for the first time."), body: WMFLocalizedString("image-rec-tooltip-3-body", value: "Decide if the image helps readers understand this topic better.", comment: "Body of second tooltip displayed when landing on image recommendations feature for the first time."), buttonTitle: CommonStrings.okTitle)

        let localizedStrings = WMFImageRecommendationsViewModel.LocalizedStrings(title: CommonStrings.addImageTitle, viewArticle: CommonStrings.viewArticle, onboardingStrings: onboardingStrings, surveyLocalizedStrings: surveyLocalizedStrings, emptyLocalizedStrings: emptyStrings, errorLocalizedStrings: errorStrings, firstTooltipStrings: firstTooltipStrings, secondTooltipStrings: secondTooltipStrings, thirdTooltipStrings: thirdTooltipStrings, bottomSheetTitle: CommonStrings.bottomSheetTitle, yesButtonTitle: CommonStrings.yesButtonTitle, noButtonTitle: CommonStrings.noButtonTitle, notSureButtonTitle: CommonStrings.notSureButtonTitle, learnMoreButtonTitle: CommonStrings.learnMoreTitle(), tutorialButtonTitle: CommonStrings.tutorialTitle, problemWithFeatureButtonTitle: CommonStrings.problemWithFeatureTitle)
        
        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: WMFLocalizedString("image-rec-survey-option-1", value: "Image is not relevant", comment: "Title of available option displayed on the image recommendations survey view."), apiIdentifer: "notrelevant"),
            WMFSurveyViewModel.OptionViewModel(text: WMFLocalizedString("image-rec-survey-option-2", value: "Not enough information to decide", comment: "Title of available option displayed on the image recommendations survey view."), apiIdentifer: "noinfo"),
            WMFSurveyViewModel.OptionViewModel(text: WMFLocalizedString("image-rec-survey-option-3", value: "Image is offensive", comment: "Title of available option displayed on the image recommendations survey view."), apiIdentifer: "offensive"),
            WMFSurveyViewModel.OptionViewModel(text: WMFLocalizedString("image-rec-survey-option-4", value: "Image is low quality", comment: "Title of available option displayed on the image recommendations survey view."), apiIdentifer: "lowquality"),
            WMFSurveyViewModel.OptionViewModel(text: WMFLocalizedString("image-rec-survey-option-5", value: "I don’t know this subject", comment: "Title of available option displayed on the image recommendations survey view."), apiIdentifer: "unfamiliar")
        ]

        let viewModel = WMFImageRecommendationsViewModel(project: project, semanticContentAttribute: semanticContentAttribute, isPermanent: dataStore.authenticationManager.authStateIsPermanent, localizedStrings: localizedStrings, surveyOptions: surveyOptions, needsSuppressPosting: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)

        let imageRecommendationsViewController = WMFImageRecommendationsViewController(viewModel: viewModel, delegate: imageRecDelegate, loggingDelegate: imageRecLoggingDelegate)
        return imageRecommendationsViewController
    }
}
