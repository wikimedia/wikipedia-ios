
import UIKit

@objc(WMFTalkPageContainerViewController)
class TalkPageContainerViewController: ViewController, HintPresenting {
    
    private let talkPageTitle: String
    private let siteURL: URL
    private let type: TalkPageType
    private let dataStore: MWKDataStore
    private let controller: TalkPageController
    private let talkPageSemanticContentAttribute: UISemanticContentAttribute
    private var talkPage: TalkPage?
    private var topicListViewController: TalkPageTopicListViewController?
    private var replyListViewController: TalkPageReplyListViewController?
    private var headerView: TalkPageHeaderView?
    private var addButton: UIBarButtonItem?
    
    @objc static let WMFReplyPublishedNotificationName = "WMFReplyPublishedNotificationName"
    @objc static let WMFTopicPublishedNotificationName = "WMFTopicPublishedNotificationName"
    
    var hintController: HintController?
    
    lazy private var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    private var repliesAreDisabled = true {
        didSet {
            replyListViewController?.repliesAreDisabled = repliesAreDisabled
        }
    }
    
    required init(title: String, siteURL: URL, type: TalkPageType, dataStore: MWKDataStore, controller: TalkPageController? = nil) {
        self.talkPageTitle = title
        self.siteURL = siteURL
        self.type = type
        self.dataStore = dataStore
        
        if let controller = controller {
            self.controller = controller
        } else {
            self.controller = TalkPageController(moc: dataStore.viewContext, title: talkPageTitle, siteURL: siteURL, type: type)
        }
        
        assert(title.contains(":"), "Title must already be prefixed with namespace.")
        
        let language = siteURL.wmf_language
        talkPageSemanticContentAttribute = MWLanguageInfo.semanticContentAttribute(forWMFLanguage: language)
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        fetch()
        setupNavigationBar()
    }
    
    override func apply(theme: Theme) {
        super.apply(theme: theme)
        view.backgroundColor = theme.colors.paperBackground
    }
}

//MARK: Private

private extension TalkPageContainerViewController {
    
    func fetch() {
        fakeProgressController.start()
        
        controller.fetchTalkPage { [weak self] (result) in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                switch result {
                case .success(let fetchResult):
                    if !fetchResult.isInitialLocalResult {
                        self.fakeProgressController.stop()
                        self.addButton?.isEnabled = true
                        self.repliesAreDisabled = false
                    }
                    
                    self.talkPage = try? self.dataStore.viewContext.existingObject(with: fetchResult.objectID) as? TalkPage
                    if let talkPage = self.talkPage {
                        if let topics = talkPage.topics, topics.count > 0 {
                            self.hideEmptyView()
                        } else {
                            self.wmf_showEmptyView(of: .emptyTalkPage, theme: self.theme, frame: self.view.bounds)
                        }
                        self.setupTopicListViewControllerIfNeeded(with: talkPage)
                        if let headerView = self.headerView {
                            self.configure(header: headerView, intro: talkPage.introText)
                            self.updateScrollViewInsets()
                        }
                    } else {
                        self.showEmptyView()
                    }
                case .failure(let error):
                    self.showEmptyView()
                    self.fakeProgressController.stop()
                    self.showNoInternetConnectionAlertOrOtherWarning(from: error)
                }
            }
        }
    }
    
    func setupTopicListViewControllerIfNeeded(with talkPage: TalkPage) {
        if topicListViewController == nil {
            topicListViewController = TalkPageTopicListViewController(dataStore: dataStore, talkPageTitle: talkPageTitle, talkPage: talkPage, siteURL: siteURL, type: type, talkPageSemanticContentAttribute: talkPageSemanticContentAttribute)
            topicListViewController?.apply(theme: theme)
            let belowView: UIView = wmf_emptyView ?? navigationBar
            wmf_add(childController: topicListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: belowView)
            topicListViewController?.delegate = self
        }
    }
    
    @objc func tappedAdd(_ sender: UIBarButtonItem) {
        let topicNewVC = TalkPageTopicNewViewController.init()
        topicNewVC.delegate = self
        topicNewVC.apply(theme: theme)
        navigationController?.pushViewController(topicNewVC, animated: true)
    }
    
    func setupAddBarButton() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tappedAdd(_:)))
        addButton.tintColor = theme.colors.link
        navigationItem.rightBarButtonItem = addButton
        navigationBar.updateNavigationItems()
        addButton.isEnabled = false
        self.addButton = addButton
        
    }
    
    func setupNavigationBar() {
        
        setupAddBarButton()
        
        if let headerView = TalkPageHeaderView.wmf_viewFromClassNib() {
            self.headerView = headerView
            configure(header: headerView, intro: nil)
            navigationBar.isBarHidingEnabled = false
            navigationBar.isUnderBarViewHidingEnabled = true
            useNavigationBarVisibleHeightForScrollViewInsets = true
            navigationBar.addUnderNavigationBarView(headerView)
            navigationBar.underBarViewPercentHiddenForShowingTitle = 0.6
            navigationBar.title = controller.displayTitle
            updateScrollViewInsets()
        }
    }
    
    func configure(header: TalkPageHeaderView, intro: String?) {
        
        var headerText: String
        switch type {
        case .user:
            headerText = WMFLocalizedString("talk-page-title-user-talk", value: "User Talk", comment: "This title label is displayed at the top of a talk page topic list, if the talk page type is a user talk page.").localizedUppercase
        case .article:
            headerText = WMFLocalizedString("talk-page-title-article-talk", value: "article Talk", comment: "This title label is displayed at the top of a talk page topic list, if the talk page type is an article talk page.").localizedUppercase
        }
        
        let languageTextFormat = WMFLocalizedString("talk-page-info-active-conversations", value: "Active conversations on %1$@ Wikipedia", comment: "This information label is displayed at the top of a talk page topic list. %1$@ is replaced by the language wiki they are using - for example, 'Active conversations on English Wikipedia'.")
        
        let genericInfoText = WMFLocalizedString("talk-page-info-active-conversations-generic", value: "Active conversations on Wikipedia", comment: "This information label is displayed at the top of a talk page topic list. This is fallback text in case a specific wiki language cannot be determined.")
        
        let infoText = stringWithLocalizedCurrentSiteLanguageReplacingPlaceholderInString(string: languageTextFormat, fallbackGenericString: genericInfoText)
        
        let viewModel = TalkPageHeaderView.ViewModel(header: headerText, title: controller.displayTitle, info: infoText, intro: intro)
        
        header.configure(viewModel: viewModel)
        header.semanticContentAttributeOverride = talkPageSemanticContentAttribute
        header.apply(theme: theme)
    }
    
    func stringWithLocalizedCurrentSiteLanguageReplacingPlaceholderInString(string: String, fallbackGenericString: String) -> String {
        
        if let code = siteURL.wmf_language,
            let language = (Locale.current as NSLocale).wmf_localizedLanguageNameForCode(code) {
            return NSString.localizedStringWithFormat(string as NSString, language) as String
        } else {
            return fallbackGenericString
        }
    }
}

// MARK: Empty & error states

extension TalkPageContainerViewController {
    private func hideEmptyView() {
        navigationBar.setNavigationBarPercentHidden(0, underBarViewPercentHidden: 0, extendedViewPercentHidden: 0, topSpacingPercentHidden: 0, animated: true)
        wmf_hideEmptyView()
    }

    private func showEmptyView() {
        navigationBar.setNavigationBarPercentHidden(1, underBarViewPercentHidden: 1, extendedViewPercentHidden: 1, topSpacingPercentHidden: 0, animated: true)
        wmf_showEmptyView(of: .unableToLoadTalkPage, theme: self.theme, frame: self.view.bounds)
    }

    private func showNoInternetConnectionAlertOrOtherWarning(from error: Error, noInternetConnectionAlertMessage: String = CommonStrings.noInternetConnection) {
        if (error as NSError).wmf_isNetworkConnectionError() {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(noInternetConnectionAlertMessage, sticky: true, dismissPreviousAlerts: true)
        } else if let talkPageError = error as? TalkPageError {
            WMFAlertManager.sharedInstance.showWarningAlert(talkPageError.localizedDescription, sticky: true, dismissPreviousAlerts: true)
        }  else {
            WMFAlertManager.sharedInstance.showErrorAlertWithMessage(error.localizedDescription, sticky: true, dismissPreviousAlerts: true)
        }
    }
}

//MARK: TalkPageTopicNewViewControllerDelegate

extension TalkPageContainerViewController: TalkPageTopicNewViewControllerDelegate {
    func tappedPublish(subject: String, body: String, viewController: TalkPageTopicNewViewController) {
        
        guard let talkPage = talkPage else {
            assertionFailure("Missing Talk Page")
            return
        }
        
        viewController.postDidBegin()
        controller.addTopic(toTalkPageWith: talkPage.objectID, title: talkPageTitle, siteURL: siteURL, subject: subject, body: body) { [weak self] (result) in
            DispatchQueue.main.async {
                viewController.postDidEnd()

                switch result {
                case .success(let result):
                    if result != .success {
                        self?.fetch()
                    }
                    self?.navigationController?.popViewController(animated: true)
                    NotificationCenter.default.post(name: Notification.Name(TalkPageContainerViewController.WMFTopicPublishedNotificationName), object: nil)
                case .failure(let error):
                    self?.showNoInternetConnectionAlertOrOtherWarning(from: error, noInternetConnectionAlertMessage: WMFLocalizedString("talk-page-error-unable-to-post-topic", value: "No internet connection. Unable to post topic.", comment: "Error message appearing when user attempts to post a new talk page topic while being offline"))
                }
            }
        }
    }
}

//MARK: TalkPageTopicListDelegate

extension TalkPageContainerViewController: TalkPageTopicListDelegate {    
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageTopicListViewController) {
        hintController?.dismissHintDueToUserInteraction()
    }
    
    func tappedTopic(_ topic: TalkPageTopic, viewController: TalkPageTopicListViewController) {
        let replyListViewController = TalkPageReplyListViewController(dataStore: dataStore, topic: topic, talkPageSemanticContentAttribute: talkPageSemanticContentAttribute)
        replyListViewController.delegate = self
        replyListViewController.apply(theme: theme)
        replyListViewController.repliesAreDisabled = repliesAreDisabled
        self.replyListViewController = replyListViewController
        navigationController?.pushViewController(replyListViewController, animated: true)
    }

    func didBecomeActiveAfterCompletingActivity(_ completedActivityType: UIActivity.ActivityType?) {
        if completedActivityType == .openInSafari {
            fetch()
        }
    }
}

//MARK: TalkPageReplyListViewControllerDelegate

extension TalkPageContainerViewController: TalkPageReplyListViewControllerDelegate {
    func tappedPublish(topic: TalkPageTopic, composeText: String, viewController: TalkPageReplyListViewController) {
        
        viewController.postDidBegin()
        controller.addReply(to: topic, title: talkPageTitle, siteURL: siteURL, body: composeText) { (result) in
            DispatchQueue.main.async {
                viewController.postDidEnd()
                NotificationCenter.default.post(name: Notification.Name(TalkPageContainerViewController.WMFReplyPublishedNotificationName), object: nil)
                
                switch result {
                case .success:
                    print("made it")
                case .failure(let error):
                    self.showNoInternetConnectionAlertOrOtherWarning(from: error, noInternetConnectionAlertMessage: WMFLocalizedString("talk-page-error-unable-to-post-reply", value: "No internet connection. Unable to post reply.", comment: "Error message appearing when user attempts to post a new talk page reply while being offline"))
                }
            }
        }
    }
    
    func tappedLink(_ url: URL, viewController: TalkPageReplyListViewController) {
        
        //todo: might want to fetch/lean on article summary for this instead to detect user talk page namespace.
        
        let lastPathComponent = url.lastPathComponent
        
        var urlForCanonicalCheck: URL?
        var urlForContainer: URL?
        if let host = url.host,
            let scheme = url.scheme {
            urlForCanonicalCheck = URL(string: "\(scheme)://\(host)")
            urlForContainer = url
        } else {
            urlForCanonicalCheck = siteURL
            urlForContainer = siteURL
        }
        
        if let urlForCanonicalCheck = urlForCanonicalCheck,
            let urlForContainer = urlForContainer,
            let prefix = type.canonicalNamespacePrefix(for: urlForCanonicalCheck)?.wmf_denormalizedPageTitle(), //todo: check for localized prefix too?
            lastPathComponent.contains(prefix) {
            let talkPageContainerVC = TalkPageContainerViewController(title: lastPathComponent, siteURL: urlForContainer, type: .user, dataStore: dataStore)
            talkPageContainerVC.apply(theme: theme)
            navigationController?.pushViewController(talkPageContainerVC, animated: true)
        }
        
        //todo: else if User: prefix, show their wikitext editing page in a web view. Ensure edits there cause talk page to refresh when coming back.
        //else if no host, try prepending language wiki to components and navigate (openUrl, is it okay that this kicks them out of the app?)
        //else if it's a full url (i.e. a different host), send them to safari
    }
}
