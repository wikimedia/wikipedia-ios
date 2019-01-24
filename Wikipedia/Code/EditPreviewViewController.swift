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
    var theme: Theme?
    weak var delegate: EditPreviewViewControllerDelegate?
    
    @IBOutlet private var previewWebViewContainer: PreviewWebViewContainer!
    private var previewHtmlFetcher: PreviewHtmlFetcher?
    
    func wmf_showAlert(forTappedAnchorHref href: String) {
        let title = WMFLocalizedStringWithDefaultValue("wikitext-preview-link-preview-title", nil, nil, "Link preview", "Title for link preview popup")
        let message = String(format: WMFLocalizedStringWithDefaultValue("wikitext-preview-link-preview-description", nil, nil, "This link leads to '%1$@'", "Description of the link URL. %1$@ is the URL."), href)
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
// TODO: move "button-ok" to common strings
        alertController.addAction(UIAlertAction(title: WMFLocalizedStringWithDefaultValue("button-ok", nil, nil, "OK", "Button text for ok button used in various places\n{{Identical|OK}}"), style: .default, handler: nil))
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
        if (theme == nil) {
            theme = .standard
        }
        
        navigationItem.title = WMFLocalizedStringWithDefaultValue("navbar-title-mode-edit-wikitext-preview", nil, nil, "Preview", "Header text shown when wikitext changes are being previewed.\n{{Identical|Preview}}")
        
        previewWebViewContainer.externalLinksOpenerDelegate = self
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(WMFButtonType.caretLeft, target: self, action: #selector(self.goBack))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CommonStrings.nextTitle, style: .plain, target: self, action: #selector(self.goForward))
        
        funnel?.logPreview()
        
        preview()
        
        if let theme = theme {
            apply(theme: theme)
        }
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
        
        QueuesSingleton.sharedInstance().sectionPreviewHtmlFetchManager.wmf_cancelAllTasks(completionHandler: {
            self.previewHtmlFetcher = PreviewHtmlFetcher.init(andFetchHtmlForWikiText: self.wikiText, articleURL: self.section?.url, with: QueuesSingleton.sharedInstance().sectionPreviewHtmlFetchManager, thenNotify: self)
        })
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

extension EditPreviewViewController: FetchFinishedDelegate {
    func fetchFinished(_ sender: Any!, fetchedData: Any!, status: FetchFinalStatus, error: Error!) {
        if (sender is PreviewHtmlFetcher) {
            switch status {
            case .FETCH_FINAL_STATUS_SUCCEEDED:
                WMFAlertManager.sharedInstance.dismissAlert()
                previewWebViewContainer.webView?.loadHTML(fetchedData as? String, baseURL: URL(string: "https://wikipedia.org"), withAssetsFile: "preview.html", scrolledToFragment: nil, padding: UIEdgeInsets.zero, theme: theme ?? .standard)
            case .FETCH_FINAL_STATUS_FAILED:
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            case .FETCH_FINAL_STATUS_CANCELLED:
                WMFAlertManager.sharedInstance.showErrorAlert(error as NSError, sticky: true, dismissPreviousAlerts: true, tapCallBack: nil)
            default:
                break
            }
        }
    }
}
