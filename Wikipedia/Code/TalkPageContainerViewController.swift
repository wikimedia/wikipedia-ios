
import UIKit

@objc(WMFTalkPageContainerViewController)
class TalkPageContainerViewController: ViewController, HintPresenting {
    
    private let talkPageTitle: String
    private let siteURL: URL
    private let type: TalkPageType
    private let dataStore: MWKDataStore
    private var controller: TalkPageController
    private var talkPage: TalkPage?
    private var topicListViewController: TalkPageTopicListViewController?
    
    @objc static let WMFReplyPublishedNotificationName = "WMFReplyPublishedNotificationName"
    @objc static let WMFTopicPublishedNotificationName = "WMFTopicPublishedNotificationName"
    
    var hintController: HintController?
    
    lazy private var fakeProgressController: FakeProgressController = {
        let progressController = FakeProgressController(progress: navigationBar, delegate: navigationBar)
        progressController.delay = 0.0
        return progressController
    }()
    
    required init(title: String, siteURL: URL, type: TalkPageType, dataStore: MWKDataStore) {
        self.talkPageTitle = title
        self.siteURL = siteURL
        self.type = type
        self.dataStore = dataStore
        self.controller = TalkPageController(moc: dataStore.viewContext, title: talkPageTitle, siteURL: siteURL, type: type)
        assert(title.contains(":"), "Title must already be prefixed with namespace.")
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
    
    func setupNavigationBar() {
        let addButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(tappedAdd(_:)))
        addButton.tintColor = theme.colors.link
        navigationItem.rightBarButtonItem = addButton
        navigationBar.updateNavigationItems()
        navigationBar.isBarHidingEnabled = false
    }
    
    @objc func tappedAdd(_ sender: UIBarButtonItem) {
        let topicNewVC = TalkPageTopicNewViewController.init()
        topicNewVC.delegate = self
        topicNewVC.apply(theme: theme)
        navigationController?.pushViewController(topicNewVC, animated: true)
    }
    
    func fetch() {
        
        //todo: loading/error/empty states
        fakeProgressController.start()
        controller.fetchTalkPage { [weak self] (result) in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                self.fakeProgressController.stop()
                
                switch result {
                case .success(let talkPageID):
                    self.talkPage = try? self.dataStore.viewContext.existingObject(with: talkPageID) as? TalkPage
                    if let talkPage = self.talkPage {
                        self.setupTopicListViewControllerIfNeeded(with: talkPage)
                    }
                case .failure(let error):
                    print("error! \(error)")
                }
            }
        }
    }
    
    func setupTopicListViewControllerIfNeeded(with talkPage: TalkPage) {
        if topicListViewController == nil {
            topicListViewController = TalkPageTopicListViewController(dataStore: dataStore, talkPage: talkPage, siteURL: siteURL, type: type)
            topicListViewController?.apply(theme: theme)
            wmf_add(childController: topicListViewController, andConstrainToEdgesOfContainerView: view, belowSubview: navigationBar)
            topicListViewController?.delegate = self
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
                case .success:
                    self?.navigationController?.popViewController(animated: true)
                    
                    NotificationCenter.default.post(name: Notification.Name(TalkPageContainerViewController.WMFTopicPublishedNotificationName), object: nil)
                case .failure:
                    break
                }
            }
        }
    }
}

//MARK: TalkPageTopicListDelegate

extension TalkPageContainerViewController: TalkPageTopicListDelegate {
    func updateNavigationBarTitle(title: String?, viewController: TalkPageTopicListViewController) {
        navigationItem.title = title
        navigationBar.updateNavigationItems()
    }
    
    func currentNavigationTitle(viewController: TalkPageTopicListViewController) -> String? {
        return navigationItem.title
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView, viewController: TalkPageTopicListViewController) {
        hintController?.dismissHintDueToUserInteraction()
    }
    
    func tappedTopic(_ topic: TalkPageTopic, viewController: TalkPageTopicListViewController) {
        let replyVC = TalkPageReplyListViewController(dataStore: dataStore, topic: topic)
        replyVC.delegate = self
        replyVC.apply(theme: theme)
        navigationController?.pushViewController(replyVC, animated: true)
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
                case .failure:
                    print("failure")
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
