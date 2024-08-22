import Foundation
import WMFComponents
import WMFData

final class AltTextImageRecommendationsOnboardingPresenter {
    
    private weak var imageRecommendationsViewModel: WMFImageRecommendationsViewModel?
    private weak var imageRecommendationsViewController: WMFImageRecommendationsViewController?
    private weak var exploreViewController: ExploreViewController?
    
    internal init(imageRecommendationsViewModel: WMFImageRecommendationsViewModel, imageRecommendationsViewController: WMFImageRecommendationsViewController, exploreViewController: ExploreViewController) {
        self.imageRecommendationsViewModel = imageRecommendationsViewModel
        self.imageRecommendationsViewController = imageRecommendationsViewController
        self.exploreViewController = exploreViewController
    }
    
    func enterAltTextFlow() {
        
        guard let dataController = WMFAltTextDataController.shared,
        let imageRecommendationsViewController else {
            return
        }
        if !dataController.hasPresentedOnboardingModal {
            presentAltTextOnboarding(imageRecommendationsViewController: imageRecommendationsViewController)
            dataController.hasPresentedOnboardingModal = true
        } else {
            pushOnAltText()
        }
    }
    
    private func pushOnAltText() {
        guard let imageRecommendationsViewModel,
              let lastRecommendation = imageRecommendationsViewModel.lastRecommendation,
              let exploreViewController,
              let imageRecommendationsViewController else {
            return
        }
        
        guard let imageWikitext = lastRecommendation.imageWikitext,
              let fullArticleWikitextWithImage = lastRecommendation.fullArticleWikitextWithImage,
            let lastRevisionID = lastRecommendation.lastRevisionID,
            let localizedFileTitle = lastRecommendation.localizedFileTitle else {
            return
        }
        
        let addAltTextTitle = CommonStrings.altTextArticleNavBarTitle
        let languageCode = imageRecommendationsViewModel.project.languageCode
        let editSummary = CommonStrings.altTextEditSummary(with: languageCode)
        
        let localizedStrings = WMFAltTextExperimentViewModel.LocalizedStrings(articleNavigationBarTitle: addAltTextTitle, editSummary: editSummary)
        
        let articleTitle = lastRecommendation.imageData.pageTitle
        
        let firstTooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings(title: CommonStrings.altTextOnboardingTooltip1Title, body: CommonStrings.altTextOnboardingTooltip1Body, buttonTitle: CommonStrings.nextTitle)
        let secondTooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings(title: CommonStrings.altTextOnboardingTooltip2Title, body: CommonStrings.altTextOnboardingTooltip2Body, buttonTitle: CommonStrings.nextTitle)
        let thirdTooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings(title: CommonStrings.altTextOnboardingTooltip3Title, body: CommonStrings.altTextOnboardingTooltip3Body, buttonTitle: CommonStrings.doneTitle)
        
        let altTextViewModel = WMFAltTextExperimentViewModel(localizedStrings: localizedStrings, firstTooltipLocalizedStrings: firstTooltipLocalizedStrings, secondTooltipLocalizedStrings: secondTooltipLocalizedStrings, thirdTooltipLocalizedStrings: thirdTooltipLocalizedStrings, articleTitle: articleTitle, caption: lastRecommendation.caption, imageFullURLString: lastRecommendation.imageData.fullUrl, imageThumbURLString: lastRecommendation.imageData.thumbUrl, filename: localizedFileTitle, imageWikitext: imageWikitext, fullArticleWikitextWithImage: fullArticleWikitextWithImage, lastRevisionID: lastRevisionID, sectionID: 0, isFlowB: true, project: imageRecommendationsViewModel.project)
        
        let textViewPlaceholder = CommonStrings.altTextViewPlaceholder
        let textViewBottomDescription = CommonStrings.altTextViewBottomDescription
        let characterCounterWarningText = CommonStrings.altTextViewCharacterCounterWarning
        let characterCounterFormat = CommonStrings.altTextViewCharacterCounterFormat
        let guidanceText = CommonStrings.altGuidanceButtonTitle
        
        let sheetLocalizedStrings = WMFAltTextExperimentModalSheetViewModel.LocalizedStrings(title: addAltTextTitle, nextButton: CommonStrings.nextTitle, textViewPlaceholder: textViewPlaceholder, textViewBottomDescription: textViewBottomDescription, characterCounterWarning: characterCounterWarningText, characterCounterFormat: characterCounterFormat, guidance: guidanceText)

        let bottomSheetViewModel = WMFAltTextExperimentModalSheetViewModel(altTextViewModel: altTextViewModel, localizedStrings: sheetLocalizedStrings)
        
        if let siteURL = imageRecommendationsViewModel.project.siteURL,
           let articleURL = siteURL.wmf_URL(withTitle: articleTitle),
           let articleViewController = ArticleViewController(articleURL: articleURL, dataStore: exploreViewController.dataStore, theme: exploreViewController.theme, altTextExperimentViewModel: altTextViewModel, needsAltTextExperimentSheet: true, altTextBottomSheetViewModel: bottomSheetViewModel, altTextDelegate: exploreViewController) {

            imageRecommendationsViewController.navigationController?.pushViewController(articleViewController, animated: true)
        }
    }
    
    private func presentAltTextOnboarding(imageRecommendationsViewController: WMFImageRecommendationsViewController) {
        
        guard let imageRecommendationsViewModel else {
            return
        }

        let onboardingController = WMFOnboardingViewController.altTextOnboardingViewController(primaryButtonTitle: CommonStrings.continueButton, delegate: self)
        imageRecommendationsViewController.present(onboardingController, animated: true, completion: {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        })
        
        EditInteractionFunnel.shared.logAltTextOnboardingDidAppear(project: WikimediaProject(wmfProject: imageRecommendationsViewModel.project))
    }
    
}

extension AltTextImageRecommendationsOnboardingPresenter: WMFOnboardingViewDelegate {
    func onboardingViewDidClickPrimaryButton() {
        
        guard let imageRecommendationsViewModel,
              let imageRecommendationsViewController else {
            return
        }
        
        EditInteractionFunnel.shared.logAltTextOnboardingDidTapPrimaryButton(project: WikimediaProject(wmfProject: imageRecommendationsViewModel.project))
        
        imageRecommendationsViewController.dismiss(animated: true) {
            self.pushOnAltText()
        }
        
    }
    
    func onboardingViewDidClickSecondaryButton() {
        
        guard let imageRecommendationsViewModel,
        let imageRecommendationsViewController else {
            return
        }

        EditInteractionFunnel.shared.logAltTextOnboardingDidTapSecondaryButton(project: WikimediaProject(wmfProject: imageRecommendationsViewModel.project))
        
        var url: URL?
        switch imageRecommendationsViewModel.project {
        case .wikipedia(let language):
            switch language.languageCode {
            case "en", "test":
                url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits/en#Alt_Text_Examples")!
            case "pt":
                url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits/pt-br#Exemplos_de_texto_alternativo")
            case "es":
                url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits/es#Ejemplos_de_texto_alternativo")
            case "zh":
                url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits/zh#%E6%9B%BF%E4%BB%A3%E6%96%87%E6%9C%AC%E7%AF%84%E4%BE%8B")
            case "fr":
                url = URL(string: "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_Suggested_edits/fr#Exemples_de_texte_alternatif")
            default:
                return
            }
        default:
            return
        }
        
        guard let url else {
            return
        }
        
        imageRecommendationsViewController.navigate(to: url, useSafari: true)
    }
    
    func onboardingDidSwipeToDismiss() {
        pushOnAltText()
    }
}
