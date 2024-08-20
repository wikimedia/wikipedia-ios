import Foundation
import WMFComponents
import WMFData

final class AltTextGuidancePresenter {
    private weak var articleViewController: ArticleViewController?
    
    internal init(articleViewController: ArticleViewController) {
        self.articleViewController = articleViewController
    }
    
    func presentAltTextGuidance() {
        
        guard let articleViewController else {
            return
        }
        
        // dismiss alt text input  half sheet modal
        articleViewController.dismiss(animated: true) {
            
            let onboardingController = WMFOnboardingViewController.altTextOnboardingViewController(primaryButtonTitle: CommonStrings.doneTitle, delegate: self)
            self.articleViewController?.present(onboardingController, animated: true, completion: {
                UIAccessibility.post(notification: .layoutChanged, argument: nil)
            })
        }
    }
}

extension AltTextGuidancePresenter: WMFOnboardingViewDelegate {
    func onboardingViewDidClickPrimaryButton() {
        
        guard let articleViewController else {
            return
        }
        
        articleViewController.dismiss(animated: true) {
            self.articleViewController?.presentAltTextModalSheet()
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
        
        guard let articleViewController else {
            return
        }
        
        articleViewController.presentAltTextModalSheet()
    }
}
