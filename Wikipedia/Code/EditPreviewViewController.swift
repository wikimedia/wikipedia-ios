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
    
    lazy var messagingController: ArticleWebMessagingController = {
        let controller = ArticleWebMessagingController()
        controller.delegate = self
        return controller
    }()
    
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
        previewWebViewContainer.webView.uiDelegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadPreviewIfNecessary()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        WMFAlertManager.sharedInstance.dismissAlert()
        super.viewWillDisappear(animated)
    }
    
    deinit {
        messagingController.removeScriptMessageHandler()
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
            #if WMF_LOCAL_PAGE_CONTENT_SERVICE || WMF_APPS_LABS_PAGE_CONTENT_SERVICE
            // If on local or staging PCS, we need to split this call. On the server, wikitext-to-mobilehtml just puts together two other
            // calls - wikitext-to-html, and html-to-mobilehtml. Since we have html-to-mobilehtml in local/staging PCS but not the first call, if
            // we're making PCS edits to mobilehtml we need this code in order to view them. We split the call (similar to what the server dioes)
            // routing the wikitext-to-html call to production, and html-to-mobilehtml to local or staging PCS.
            let completion: ((String?, URL?) -> Void) = { [weak self] (html, responseUrl)  in
                DispatchQueue.main.async {
                    guard let html = html else {
                        self?.showGenericError()
                        return
                    }
                    // While we'd normally expect this second request to be able to loaded via `...webView.load(request)`, for unknown
                    // reasons it wasn't working in that route - but was working when loaded via HTML string (in completion handler) -
                    // despite both responses being identical when inspected via a proxy server.
                    self?.previewWebViewContainer.webView.loadHTMLString(html, baseURL: responseUrl)
                }
            }
            try fetcher.fetchMobileHTMLFromWikitext(articleURL: articleURL, wikitext: wikitext, mobileHTMLOutput: .editPreview, completion: completion)
            #else
            let request = try fetcher.wikitextToMobileHTMLPreviewRequest(articleURL: articleURL, wikitext: wikitext)
            previewWebViewContainer.webView.load(request)
            #endif
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
                    let encodedTitle = title.percentEncodedPageTitleForPathComponents,
                    let newArticleURL = Configuration.current.articleURLForHost(host, appending: [encodedTitle]).url else {
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

// MARK:- Context Menu (iOS 13 and later)
// All functions in this extension are for Context Menus (used in iOS 13 and later)
extension EditPreviewViewController: ArticleContextMenuPresenting, WKUIDelegate {
    func getPeekViewControllerAsync(for destination: Router.Destination, completion: @escaping (UIViewController?) -> Void) {
        completion(getPeekViewController(for: destination))
    }

    @available(iOS 13.0, *)
    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {

        self.contextMenuConfigurationForElement(elementInfo, completionHandler: completionHandler)
    }

//    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: WKContextMenuElementInfo, willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating)
//    No function with this signature, as we don't want to have any context menu elements in preview - and we get that behavior by default by not implementing this.

    // This function is used by both Peek/Pop and Context Menu (can remove this note when removing rest of Peek/Pop code, when oldest supported version is iOS 13)
    func getPeekViewController(for destination: Router.Destination) -> UIViewController? {
        let dataStore = MWKDataStore.shared()
        switch destination {
        case .article(let articleURL):
            return ArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        default:
            return nil
        }
    }

    // This function is used by both Peek/Pop and Context Menu (can remove this note when removing rest of Peek/Pop code, when oldest supported version is iOS 13)
    // This function needed is for ArticleContextMenuPresenting, but not applicable to EditPreviewVC
    func hideFindInPage(_ completion: (() -> Void)? = nil) {
    }
}

// MARK: Peek/Pop (iOS 12 and earlier, on devices w/ 3D Touch)
// All functions in this extension are for 3D Touch menus. (Can be removed when the oldest supported version is iOS 13.)
extension EditPreviewViewController {
    var configuration: Configuration {
        return Configuration.current
    }

    func webView(_ webView: WKWebView, shouldPreviewElement elementInfo: WKPreviewElementInfo) -> Bool {
        return self.shouldPreview(linkURL: elementInfo.linkURL)
    }

    func webView(_ webView: WKWebView, previewingViewControllerForElement elementInfo: WKPreviewElementInfo, defaultActions previewActions: [WKPreviewActionItem]) -> UIViewController? {
        return self.previewingViewController(for: elementInfo.linkURL)
    }

    func webView(_ webView: WKWebView, commitPreviewingViewController previewingViewController: UIViewController) {
        // If EditPreviewInternalLinkViewController ever gets refactored, would be nice to break apart it's internal containerView so that here we could wrap
        // previewingViewController in an EditPreviewInternalLinkViewController. (For now, just loading a new EditPreviewInternalLinkVC would load the articleURL in
        // viewDidLoad - before we could hijack it - and so we're just reloading our preview again.)
        guard let url = (previewingViewController as? ArticlePeekPreviewViewController)?.articleURL else {
            return
        }
        showInternalLink(url: url)
    }
}
