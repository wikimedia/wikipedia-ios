import UIKit
import WMF

protocol EditPreviewViewControllerDelegate: NSObjectProtocol {
    func editPreviewViewControllerDidTapNext(_ editPreviewViewController: EditPreviewViewController)
}

class EditPreviewViewController: ViewController, WMFPreviewAnchorTapAlertDelegate, InternalLinkPreviewing {
    var sectionID: Int?
    var articleURL: URL
    var languageCode: String?
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

    private let previewWebViewContainer: PreviewWebViewContainer

    var scrollToAnchorCompletions: [ScrollToAnchorCompletion] = []
    var scrollViewAnimationCompletions: [() -> Void] = []

    lazy var referenceWebViewBackgroundTapGestureRecognizer: UITapGestureRecognizer = {
        let tapGR = UITapGestureRecognizer(target: self, action: #selector(tappedWebViewBackground))
        tapGR.delegate = self
        webView.scrollView.addGestureRecognizer(tapGR)
        tapGR.isEnabled = false
        return tapGR
    }()

    init(articleURL: URL) {
        self.articleURL = articleURL
        self.previewWebViewContainer = PreviewWebViewContainer()
        super.init()

        webView.scrollView.delegate = self
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func previewWebViewContainer(_ previewWebViewContainer: PreviewWebViewContainer, didTapLink url: URL) {
        let isExternal = url.host != articleURL.host
        if isExternal {
            showExternalLinkInAlert(link: url.absoluteString)
        } else {
            showInternalLink(url: url)
        }
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

        view.addSubview(previewWebViewContainer)
        view.wmf_addConstraintsToEdgesOfView(previewWebViewContainer)
        previewWebViewContainer.previewAnchorTapAlertDelegate = self
        
        navigationItem.title = WMFLocalizedString("navbar-title-mode-edit-wikitext-preview", value: "Preview", comment: "Header text shown when wikitext changes are being previewed. {{Identical|Preview}}")
                
        navigationItem.leftBarButtonItem = UIBarButtonItem.wmf_buttonType(.caretLeft, target: self, action: #selector(self.goBack))
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: CommonStrings.nextTitle, style: .done, target: self, action: #selector(self.goForward))
        navigationItem.rightBarButtonItem?.tintColor = theme.colors.link

        if let loggedEditActions = loggedEditActions,
            !loggedEditActions.contains(EditFunnel.Action.preview) {
            editFunnel?.logEditPreviewForArticle(from: editFunnelSource, language: languageCode)
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
    
    private var hasPreviewed = false

    private func loadPreviewIfNecessary() {
        guard !hasPreviewed else {
            return
        }
        hasPreviewed = true
        messagingController.setup(with: previewWebViewContainer.webView, languageCode: languageCode ?? "en", theme: theme, layoutMargins: articleMargins, areTablesInitiallyExpanded: true)
        WMFAlertManager.sharedInstance.showAlert(WMFLocalizedString("wikitext-preview-changes", value: "Retrieving preview of your changes...", comment: "Alert text shown when getting preview of user changes to wikitext"), sticky: false, dismissPreviousAlerts: true, tapCallBack: nil)
        
        let pcsLocalAndStagingEnvironmentsCompletion: () throws -> Void = { [weak self] in
            
            guard let self = self else {
                return
            }
            
            // If on local or staging PCS, we need to split this call. On the RESTBase server, wikitext-to-mobilehtml just puts together two other
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
            try self.fetcher.fetchMobileHTMLFromWikitext(articleURL: self.articleURL, wikitext: self.wikitext, mobileHTMLOutput: .editPreview, completion: completion)
        }
        
        let pcsProductionCompletion: () throws -> Void = { [weak self] in
            
            guard let self = self else {
                return
            }
            
            let request = try self.fetcher.wikitextToMobileHTMLPreviewRequest(articleURL: self.articleURL, wikitext: self.wikitext, mobileHTMLOutput: .editPreview)
            self.previewWebViewContainer.webView.load(request)
        }
        
        do {
            let environment = Configuration.current.environment
            switch environment {
            case .local(let options):
                if options.contains(.localPCS) {
                    try pcsLocalAndStagingEnvironmentsCompletion()
                    return
                }
                try pcsProductionCompletion()
            case .staging(let options):
                if options.contains(.appsLabsforPCS) {
                    try pcsLocalAndStagingEnvironmentsCompletion()
                    return
                }
                try pcsProductionCompletion()
            default:
                try pcsProductionCompletion()
            }
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

    @objc func tappedWebViewBackground() {
        dismissReferenceBackLinksViewController()
    }
}

// MARK:- References
extension EditPreviewViewController: WMFReferencePageViewAppearanceDelegate, ReferenceViewControllerDelegate, UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        didFinishAnimating(pageViewController)
    }
}

extension EditPreviewViewController: ReferenceBackLinksViewControllerDelegate, ReferenceShowing {
    var webView: WKWebView {
        return previewWebViewContainer.webView
    }
}

extension EditPreviewViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return shouldRecognizeSimultaneousGesture(recognizer: gestureRecognizer)
    }
}

extension EditPreviewViewController: ArticleWebMessageHandling {
    func didRecieve(action: ArticleWebMessagingController.Action) {
        switch action {
        case .unknown(let href):
            showExternalLinkInAlert(link: href)
        case .backLink(let referenceId, let referenceText, let backLinks):
            showReferenceBackLinks(backLinks, referenceId: referenceId, referenceText: referenceText)
        case .reference(let index, let group):
            showReferences(group, selectedIndex: index, animated: true)
        case .link(let href, _, let title):
            if let title = title, !title.isEmpty {
                guard
                    let host = articleURL.host,
                    let encodedTitle = title.percentEncodedPageTitleForPathComponents,
                    let newArticleURL = Configuration.current.articleURLForHost(host, languageVariantCode: articleURL.wmf_languageVariantCode, appending: [encodedTitle]) else {
                    showInternalLinkInAlert(link: href)
                    break
                }
                showInternalLink(url: newArticleURL)
            } else {
                showExternalLinkInAlert(link: href)
            }
        case .scrollToAnchor(let anchor, let rect):
            scrollToAnchorCompletions.popLast()?(anchor, rect)
        default:
            break
        }
    }

    internal func updateArticleMargins() {
        messagingController.updateMargins(with: articleMargins, leadImageHeight: 0)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        let marginUpdater: ((UIViewControllerTransitionCoordinatorContext) -> Void) = { _ in self.updateArticleMargins() }
        coordinator.animate(alongsideTransition: marginUpdater)
    }
}

// MARK:- Context Menu

extension EditPreviewViewController: ArticleContextMenuPresenting, WKUIDelegate {
    var configuration: Configuration {
        return Configuration.current
    }
    
    func getPeekViewControllerAsync(for destination: Router.Destination, completion: @escaping (UIViewController?) -> Void) {
        completion(getPeekViewController(for: destination))
    }

    func webView(_ webView: WKWebView, contextMenuConfigurationForElement elementInfo: WKContextMenuElementInfo, completionHandler: @escaping (UIContextMenuConfiguration?) -> Void) {

        self.contextMenuConfigurationForElement(elementInfo, completionHandler: completionHandler)
    }

//    func webView(_ webView: WKWebView, contextMenuForElement elementInfo: WKContextMenuElementInfo, willCommitWithAnimator animator: UIContextMenuInteractionCommitAnimating)
//    No function with this signature, as we don't want to have any context menu elements in preview - and we get that behavior by default by not implementing this.

    func getPeekViewController(for destination: Router.Destination) -> UIViewController? {
        let dataStore = MWKDataStore.shared()
        switch destination {
        case .article(let articleURL):
            return ArticlePeekPreviewViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
        default:
            return nil
        }
    }

    // This function needed is for ArticleContextMenuPresenting, but not applicable to EditPreviewVC
    func hideFindInPage(_ completion: (() -> Void)? = nil) {
    }
}
