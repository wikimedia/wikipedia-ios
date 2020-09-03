import UIKit
import WMF

protocol EditPreviewViewControllerDelegate: NSObjectProtocol {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController)
}

class EditPreviewViewController: ViewController, WMFPreviewSectionLanguageInfoDelegate, WMFPreviewAnchorTapAlertDelegate {
    var sectionID: Int?
    var articleURL: URL?
    var language: String?
    var wikitext = ""
    var editFunnel: EditFunnel?
    var loggedEditActions: NSMutableSet?
    var editFunnelSource: EditFunnelSource = .unknown
    var savedPagesFunnel: SavedPagesFunnel?
    
    weak var delegate: EditPreviewViewControllerDelegate?
    
    lazy var messagingController: ArticleWebMessagingController = ArticleWebMessagingController(delegate: self)
    lazy var fetcher = ArticleFetcher()
    
    @IBOutlet private var previewWebViewContainer: PreviewWebViewContainer!

    func previewWebViewContainer(_ previewWebViewContainer: PreviewWebViewContainer, didTapLink url: URL) {
        let isExternal = url.host != articleURL?.host
        if isExternal {
            showExternalLinkInAlert(link: url.absoluteString)
        } else {
            showInternalLink(url: url)
        }
    }
    
    func showInternalLink(url: URL) {
        let exists: Bool
        if let query = url.query {
            exists = !query.contains("redlink=1")
        } else {
            exists = true
        }
        if !exists {
            showRedLinkInAlert()
            return
        }
        let dataStore = MWKDataStore.shared()
        let internalLinkViewController = EditPreviewInternalLinkViewController(articleURL: url, dataStore: dataStore)
        internalLinkViewController.modalPresentationStyle = .overCurrentContext
        internalLinkViewController.modalTransitionStyle = .crossDissolve
        internalLinkViewController.apply(theme: theme)
        present(internalLinkViewController, animated: true, completion: nil)
    }
    
    func showRedLinkInAlert() {
        let title = WMFLocalizedString("wikitext-preview-link-not-found-preview-title", value: "No internal link found", comment: "Title for nonexistent link preview popup")
        let message = WMFLocalizedString("wikitext-preview-link-not-found-preview-description", value: "Wikipedia does not have an article with this exact name", comment: "Description for nonexistent link preview popup")
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default))
        present(alertController, animated: true)
    }

    func showExternalLinkInAlert(link: String) {
        let title = WMFLocalizedString("wikitext-preview-link-external-preview-title", value: "External link", comment: "Title for external link preview popup")
        let message = String(format: WMFLocalizedString("wikitext-preview-link-external-preview-description", value: "This link leads to an external website: %1$@", comment: "Description for external link preview popup. $1$@ is the external url."), link)
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonStrings.okTitle, style: .default, handler: nil))
        present(alertController, animated: true)
    }
    
    func showInternalLinkInAlert(link: String) {
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
        
        navigationItem.title = WMFLocalizedString("navbar-title-mode-edit-wikitext-preview", value: "Preview", comment: "Header text shown when wikitext changes are being previewed. {{Identical|Preview}}")
                
        navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.caretLeft, target: self, action: #selector(self.goBack))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(self.goForward))
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link

        if let loggedEditActions = loggedEditActions,
            !loggedEditActions.contains(EditFunnel.Action.preview) {
            editFunnel?.logEditPreviewForArticle(from: editFunnelSource, language: language)
            loggedEditActions.add(EditFunnel.Action.preview)
        }
        apply(theme: theme)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPreviewIfNecessary()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        super.viewWillDisappear(animated)
    }
    
    func wmf_editedSectionLanguageInfo() -> MWLanguageInfo? {
        guard let lang = language else {
            return nil
        }
        return MWLanguageInfo(forCode: lang)
    }
    
    private var hasPreviewed = false

    private func loadPreviewIfNecessary() {
        guard !hasPreviewed else {
            return
        }
        hasPreviewed = true
        guard let articleURL = articleURL else {
            showGenericError()
            return
        }
        messagingController.setup(with: previewWebViewContainer.webView, language: language ?? "en", theme: theme, layoutMargins: articleMargins, areTablesInitiallyExpanded: true)
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("wikitext-preview-changes", value: "Retrieving preview of your changes...", comment: "Alert text shown when getting preview of user changes to wikitext"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        do {
            let request = try fetcher.mobileHTMLPreviewRequest(articleURL: articleURL, wikitext: wikitext)
            previewWebViewContainer.webView.load(request)
        } catch {
            showGenericError()
        }
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        if viewIfLoaded == nil {
            return
        }
        previewWebViewContainer.apply(theme: theme)
    }
}


extension EditPreviewViewController: ArticleWebMessageHandling {
    func didRecieve(action: ArticleWebMessagingController.Action) {
        switch action {
        case .unknown(let href):
            showExternalLinkInAlert(link: href)
        case .link(let href, _, let title):
            if let title = title {
                guard
                    let host = articleURL?.host,
                    let newArticleURL = ArticleURLConverter.desktopURL(host: host, title: title)
                else {
                    showInternalLinkInAlert(link: href)
                    break
                }
                showInternalLink(url: newArticleURL)
            } else {
                showExternalLinkInAlert(link: href)
            }
        default:
            break
        }
    }
}
