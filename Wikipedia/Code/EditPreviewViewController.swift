import UIKit
import WMF

protocol EditPreviewViewControllerDelegate: NSObjectProtocol {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController)
}

class EditPreviewViewController: UIViewController, Themeable, UITextFieldDelegate, UIScrollViewDelegate, WMFOpenExternalLinkDelegate, WMFPreviewSectionLanguageInfoDelegate, WMFPreviewAnchorTapAlertDelegate {
    var section: MWKSection?
    var wikiText = ""
    var funnel: EditFunnel?
    var savedPagesFunnel: SavedPagesFunnel?
    var theme: Theme = .standard
    weak var delegate: EditPreviewViewControllerDelegate?
    
    @IBOutlet private var previewWebViewContainer: PreviewWebViewContainer!
    private let fetcher: PreviewHtmlFetcher = PreviewHtmlFetcher()
    
    func wmf_showAlert(forTappedAnchorHref href: String) {
        let title = WMFLocalizedStringWithDefaultValue("wikitext-preview-link-preview-title", nil, nil, "Link preview", "Title for link preview popup")
        let message = String(format: WMFLocalizedStringWithDefaultValue("wikitext-preview-link-preview-description", nil, nil, "This link leads to '%1$@'", "Description of the link URL. %1$@ is the URL."), href)
        
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
        
        navigationItem.title = WMFLocalizedStringWithDefaultValue("navbar-title-mode-edit-wikitext-preview", nil, nil, "Preview", "Header text shown when wikitext changes are being previewed.\n{{Identical|Preview}}")
        
        previewWebViewContainer.externalLinksOpenerDelegate = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.caretLeft, target: self, action: #selector(self.goBack))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CommonStrings.nextTitle, style: .plain, target: self, action: #selector(self.goForward))
        
        funnel?.logPreview()
        
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

    func preview() {
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedStringWithDefaultValue("wikitext-preview-changes", nil, nil, "Retrieving preview of your changes...", "Alert text shown when getting preview of user changes to wikitext"), sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
        
        fetcher.fetchHTML(forWikiText: self.wikiText, articleURL: self.section?.url) { (previewHTML, error) in
            DispatchQueue.main.async {
                if let error = error {
                    WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
                    return
                }
                WMFAlertManager.sharedInstance.dismissAlert()
                self.previewWebViewContainer.webView?.loadHTML(previewHTML, baseURL: URL(string: "https://wikipedia.org"), withAssetsFile: "preview.html", scrolledToFragment: nil, padding: UIEdgeInsets.zero, theme: self.theme)
            }
        }
    }
    
    func apply(theme: Theme) {
        self.theme = theme
        if viewIfLoaded == nil {
            return
        }
        previewWebViewContainer.webView?.isOpaque = false
        previewWebViewContainer.webView?.scrollView.backgroundColor = .clear
        previewWebViewContainer.webView?.backgroundColor = theme.colors.paperBackground
        previewWebViewContainer.backgroundColor = theme.colors.paperBackground
    }
}
