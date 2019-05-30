import UIKit
import WMF

protocol EditPreviewViewControllerDelegate: NSObjectProtocol {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController)
}

class EditPreviewViewController: UIViewController, Themeable, WMFOpenExternalLinkDelegate, WMFPreviewSectionLanguageInfoDelegate, WMFPreviewAnchorTapAlertDelegate {
    var section: MWKSection?
    var wikitext = ""
    var funnel: EditFunnel?
    var savedPagesFunnel: SavedPagesFunnel?
    var theme: Theme = .standard
    
    weak var delegate: EditPreviewViewControllerDelegate?
    
    @IBOutlet private var previewWebViewContainer: PreviewWebViewContainer!
    private let fetcher = PreviewHtmlFetcher()

    func previewWebViewContainer(_ previewWebViewContainer: PreviewWebViewContainer, didTapLink url: URL, exists: Bool, isExternal: Bool) {
        if !exists {
            let title = WMFLocalizedString("wikitext-preview-link-not-found-preview-title", value: "No internal link found", comment: "Title for nonexistent link preview popup")
            let message = WMFLocalizedString("wikitext-preview-link-not-found-preview-description", value: "Wikipedia does not have an article with this exact name", comment: "Description for nonexistent link preview popup")
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default))
            present(alertController, animated: true)
        } else if isExternal {
            let title = WMFLocalizedString("wikitext-preview-link-external-preview-title", value: "External link", comment: "Title for external link preview popup")
            let message = String(format: WMFLocalizedString("wikitext-preview-link-external-preview-description", value: "This link leads to an external website: %1$@", comment: "Description for external link preview popup. $1$@ is the external url."), url.absoluteString)
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default, handler: nil))
            present(alertController, animated: true)
        } else {
            guard
                let dataStore = SessionSingleton.sharedInstance()?.dataStore,
                let language = section?.articleLanguage,
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false),
                let host = components.host
            else {
                showInternalLinkInAlert(link: url.absoluteString)
                return
            }
            components.host = "\(language).\(host)"
            guard let articleURL = components.url else {
                showInternalLinkInAlert(link: url.absoluteString)
                return
            }
            let internalLinkViewController = EditPreviewInternalLinkViewController(articleURL: articleURL, dataStore: dataStore)
            internalLinkViewController.modalPresentationStyle = .overCurrentContext
            internalLinkViewController.modalTransitionStyle = .crossDissolve
            internalLinkViewController.apply(theme: theme)
            present(internalLinkViewController, animated: true, completion: nil)
        }
    }

    private func showInternalLinkInAlert(link: String) {
        let title = WMFLocalizedString("wikitext-preview-link-preview-title", value: "Link preview", comment: "Title for link preview popup")
        let message = String(format: WMFLocalizedString("wikitext-preview-link-preview-description", value: "This link leads to '%1$@'", comment: "Description of the link URL. %1$@ is the URL."), link)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default, handler: nil))
        present(alertController, animated: true)
    }

    @objc func goBack() {
        navigationController?.popViewController(animated: true)
    }
    
    @objc func goForward() {
        delegate?.editPreviewViewControllerDidTapNext(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationItem.title = WMFLocalizedString("navbar-title-mode-edit-wikitext-preview", value: "Preview", comment: "Header text shown when wikitext changes are being previewed.\n{{Identical|Preview}}")
        
        previewWebViewContainer.externalLinksOpenerDelegate = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.caretLeft, target: self, action: #selector(self.goBack))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(self.goForward))
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link
        
        funnel?.logEditPreviewForArticle(withRevision: section?.article?.revisionId?.intValue, language: section?.articleLanguage)
        
        preview()
        
        apply(theme: theme)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        super.viewWillDisappear(animated)
    }
    
    func wmf_editedSectionLanguageInfo() -> MWLanguageInfo? {
        guard let lang = section?.url?.wmf_language else {
            return nil
        }
        return MWLanguageInfo(forCode: lang)
    }

    private func preview() {
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("wikitext-preview-changes", value: "Retrieving preview of your changes...", comment: "Alert text shown when getting preview of user changes to wikitext"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        
        fetcher.fetchHTML(forWikiText: wikitext, articleURL: section?.url) { (previewHTML, error) in
            DispatchQueue.main.async {
                if let error = error {
                    WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                    return
                }
                WMFAlertManager.sharedInstance.dismissAlert()
                self.previewWebViewContainer.webView.loadHTML(previewHTML, baseURL: URL(string: "https://wikipedia.org"), withAssetsFile: "preview.html", scrolledToFragment: nil, padding: UIEdgeInsets.zero, theme: self.theme)
            }
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        if viewIfLoaded == nil {
            return
        }
        previewWebViewContainer.apply(theme: theme)
    }
}
