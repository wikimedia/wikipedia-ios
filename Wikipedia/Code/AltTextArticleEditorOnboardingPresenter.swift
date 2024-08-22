import Foundation
import WMFComponents
import WMFData

struct ArticleAltTextInfo {
    let missingAltTextLink: WMFMissingAltTextLink
    let filename: String
    let articleTitle: String
    let fullArticleWikitext: String
    let lastRevisionID: UInt64
    let wmfProject: WMFProject
}

final class AltTextArticleEditorOnboardingPresenter {
    
    private weak var articleViewController: ArticleViewController?
    let altTextInfo: ArticleAltTextInfo
    
    internal init(articleViewController: ArticleViewController, altTextInfo: ArticleAltTextInfo) {
        self.articleViewController = articleViewController
        self.altTextInfo = altTextInfo
    }
    
    func enterAltTextFlow() {
        guard let dataController = WMFAltTextDataController.shared else {
            return
        }
        
        if !dataController.hasPresentedOnboardingModal {
            presentAltTextOnboarding()
            dataController.hasPresentedOnboardingModal = true
        } else {
            pushOnAltText(info: altTextInfo)
        }
    }
    
    private func presentAltTextOnboarding() {
        
        guard let articleViewController else {
            return
        }

        let onboardingController = WMFOnboardingViewController.altTextOnboardingViewController(primaryButtonTitle: CommonStrings.continueButton, delegate: self)
        articleViewController.present(onboardingController, animated: true, completion: {
            UIAccessibility.post(notification: .layoutChanged, argument: nil)
        })
        
        EditInteractionFunnel.shared.logAltTextOnboardingDidAppear(project: WikimediaProject(wmfProject: altTextInfo.wmfProject))
    }
    
    private func pushOnAltText(info: ArticleAltTextInfo) {
        
        guard let articleViewController else {
            return
        }
        
        guard let languageCode = articleViewController.articleURL.wmf_languageCode else {
            return
        }
        
        let addAltTextTitle = CommonStrings.altTextArticleNavBarTitle
        let editSummary = CommonStrings.altTextEditSummary(with: articleViewController.articleURL.wmf_languageCode)
        let localizedStrings = WMFAltTextExperimentViewModel.LocalizedStrings(articleNavigationBarTitle: addAltTextTitle, editSummary: editSummary)
        
        var caption: String? = nil
        if #available(iOS 16.0, *) {
            caption = try? info.missingAltTextLink.extractCaptionForDisplay(languageCode: languageCode)
        } else {
            caption = nil
        }
        
        let firstTooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings(title: CommonStrings.altTextOnboardingTooltip1Title, body: CommonStrings.altTextOnboardingTooltip1Body, buttonTitle: CommonStrings.nextTitle)
        let secondTooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings(title: CommonStrings.altTextOnboardingTooltip2Title, body: CommonStrings.altTextOnboardingTooltip2Body, buttonTitle: CommonStrings.nextTitle)
        let thirdTooltipLocalizedStrings = WMFTooltipViewModel.LocalizedStrings(title: CommonStrings.altTextOnboardingTooltip3Title, body: CommonStrings.altTextOnboardingTooltip3Body, buttonTitle: CommonStrings.doneTitle)
        
        let altTextViewModel = WMFAltTextExperimentViewModel(localizedStrings: localizedStrings, firstTooltipLocalizedStrings: firstTooltipLocalizedStrings, secondTooltipLocalizedStrings: secondTooltipLocalizedStrings, thirdTooltipLocalizedStrings: thirdTooltipLocalizedStrings, articleTitle: info.articleTitle, caption: caption, imageFullURLString: nil, imageThumbURLString: nil, filename: info.filename, imageWikitext: info.missingAltTextLink.text, fullArticleWikitextWithImage: info.fullArticleWikitext, lastRevisionID: info.lastRevisionID, sectionID: nil, isFlowB: false, project: info.wmfProject)
        
        let textViewPlaceholder = CommonStrings.altTextViewPlaceholder
        let textViewBottomDescription = CommonStrings.altTextViewBottomDescription
        let characterCounterWarningText = CommonStrings.altTextViewCharacterCounterWarning
        let characterCounterFormat = CommonStrings.altTextViewCharacterCounterFormat
        let guidanceText = CommonStrings.altGuidanceButtonTitle
        
        let sheetLocalizedStrings = WMFAltTextExperimentModalSheetViewModel.LocalizedStrings(title: addAltTextTitle, nextButton: CommonStrings.nextTitle, textViewPlaceholder: textViewPlaceholder, textViewBottomDescription: textViewBottomDescription, characterCounterWarning: characterCounterWarningText, characterCounterFormat: characterCounterFormat, guidance: guidanceText)

        let bottomSheetViewModel = WMFAltTextExperimentModalSheetViewModel(altTextViewModel: altTextViewModel, localizedStrings: sheetLocalizedStrings)
        
        if let articleViewController = ArticleViewController(articleURL: articleViewController.articleURL, dataStore: articleViewController.dataStore, theme: articleViewController.theme, altTextExperimentViewModel: altTextViewModel, needsAltTextExperimentSheet: true, altTextBottomSheetViewModel: bottomSheetViewModel, altTextDelegate: articleViewController) {
            
            self.articleViewController?.navigationController?.pushViewController(articleViewController, animated: true)
        }
    }
}

extension AltTextArticleEditorOnboardingPresenter: WMFOnboardingViewDelegate {
    func onboardingViewDidClickPrimaryButton() {
        
        guard let articleViewController else {
            return
        }
        
        articleViewController.dismiss(animated: true) {
            self.pushOnAltText(info: self.altTextInfo)
        }
        
        if let siteURL = articleViewController.articleURL.wmf_site,
           let project = WikimediaProject(siteURL: siteURL) {
            EditInteractionFunnel.shared.logAltTextOnboardingDidTapPrimaryButton(project: project)
        }
    }
    
    func onboardingViewDidClickSecondaryButton() {
        
        guard let articleViewController else {
            return
        }
        
        guard let siteURL = articleViewController.articleURL.wmf_site,
              let wikimediaProject = WikimediaProject(siteURL: siteURL),
        let wmfProject = wikimediaProject.wmfProject else {
            return
        }
        
        EditInteractionFunnel.shared.logAltTextOnboardingDidTapSecondaryButton(project: wikimediaProject)
        
        var url: URL?
        switch wmfProject {
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
        
        articleViewController.navigate(to: url, useSafari: true)
    }
    
    func onboardingDidSwipeToDismiss() {
        self.pushOnAltText(info: altTextInfo)
    }
}
