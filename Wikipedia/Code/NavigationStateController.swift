protocol DetailPresentingFromContentGroup {
    var contentGroupIDURIString: String? { get }
}

@objcMembers final class NavigationStateController: NSObject {
    private let key = "nav_state"
    private let dataStore: MWKDataStore

    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }

    private typealias ViewController = NavigationState.ViewController
    private typealias Presentation = ViewController.Presentation
    private typealias Info = ViewController.Info

    private struct NavigationState: Codable {
        var viewControllers: [ViewController]

        struct ViewController: Codable {
            var kind: Kind
            var presentation: Presentation
            var info: Info?
            var children: [ViewController]

            mutating func updateChildren(_ children: [ViewController]) {
                self.children = children
            }

            init?(kind: Kind?, presentation: Presentation, info: Info? = nil, children: [ViewController] = []) {
                guard let kind = kind else {
                    return nil
                }
                self.kind = kind
                self.presentation = presentation
                self.info = info
                self.children = children
            }

            enum Kind: Int, Codable {
                case tab

                case article
                case random
                case themeableNavigationController
                case settings

                case account
                case talkPage
                case talkPageReplyList

                case readingListDetail

                case detail

                init?(from rawValue: Int?) {
                    guard let rawValue = rawValue else {
                        return nil
                    }
                    self.init(rawValue: rawValue)
                }
            }

            enum Presentation: Int, Codable {
                case push
                case modal
            }

            struct Info: Codable {
                var selectedIndex: Int?

                var articleKey: String?
                var articleSectionAnchor: String?

                var talkPageSiteURLString: String?
                var talkPageTitle: String?
                var talkPageTypeRawValue: Int?

                var talkPageTopicURIString: String?

                var currentSavedViewRawValue: Int?

                var readingListURIString: String?

                var searchTerm: String?

                var contentGroupIDURIString: String?

                // TODO: Remove after moving to Swift 5.1 -
                // https://github.com/apple/swift-evolution/blob/master/proposals/0242-default-values-memberwise.md
                init(selectedIndex: Int? = nil, articleKey: String? = nil, articleSectionAnchor: String? = nil, talkPageSiteURLString: String? = nil, talkPageTitle: String? = nil, talkPageTypeRawValue: Int? = nil, talkPageTopicURIString: String? = nil, currentSavedViewRawValue: Int? = nil, readingListURIString: String? = nil, searchTerm: String? = nil, contentGroupIDURIString: String? = nil) {
                    self.selectedIndex = selectedIndex
                    self.articleKey = articleKey
                    self.articleSectionAnchor = articleSectionAnchor
                    self.talkPageSiteURLString = talkPageSiteURLString
                    self.talkPageTitle = talkPageTitle
                    self.talkPageTypeRawValue = talkPageTypeRawValue
                    self.talkPageTopicURIString = talkPageTopicURIString
                    self.currentSavedViewRawValue = currentSavedViewRawValue
                    self.readingListURIString = readingListURIString
                    self.searchTerm = searchTerm
                    self.contentGroupIDURIString = contentGroupIDURIString
                }
            }
        }
    }

    func restoreNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        guard let tabBarController = navigationController.viewControllers.first as? UITabBarController else {
            assertionFailure("Expected root view controller to be UITabBarController")
            return
        }
        guard let navigationState = navigationState(in: moc) else {
            return
        }
        WMFAuthenticationManager.sharedInstance.attemptLogin {
            for viewController in navigationState.viewControllers {
                self.restore(viewController: viewController, for: tabBarController, navigationController: navigationController, in: moc)
            }
        }
    }

    private func navigationState(in moc: NSManagedObjectContext) -> NavigationState? {
        let keyValue = moc.wmf_keyValue(forKey: key)
        guard let value = keyValue?.value as? Data else {
            return nil
        }
        let decoder = PropertyListDecoder()
        guard let navigationState = try? decoder.decode(NavigationState.self, from: value) else {
            return nil
        }
        return navigationState
    }

    func allPreservedArticleKeys(in moc: NSManagedObjectContext) -> [String]? {
        return navigationState(in: moc)?.viewControllers.compactMap { $0.info?.articleKey }
    }

    private func pushOrPresent(_ viewController: UIViewController, navigationController: UINavigationController, presentation: Presentation, animated: Bool = false) {
        switch presentation {
        case .push:
            navigationController.pushViewController(viewController, animated: animated)
        case .modal:
            navigationController.present(viewController, animated: animated)
        }
    }

    private func articleURL(from info: Info) -> URL? {
        guard
            let articleKey = info.articleKey,
            var articleURL = URL(string: articleKey)
        else {
            return nil
        }
        if let sectionAnchor = info.articleSectionAnchor, let articleURLWithFragment = articleURL.wmf_URL(withFragment: sectionAnchor) {
            articleURL = articleURLWithFragment
        }
        return articleURL
    }

    private func restore(viewController: ViewController, for tabBarController: UITabBarController, navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        var newNavigationController: UINavigationController?

        if let info = viewController.info, let selectedIndex = info.selectedIndex {
            tabBarController.selectedIndex = selectedIndex
            switch tabBarController.selectedViewController {
            case let savedViewController as SavedViewController:
                guard let currentSavedViewRawValue = info.currentSavedViewRawValue else {
                    return
                }
                savedViewController.toggleCurrentView(currentSavedViewRawValue)
            case let searchViewController as SearchViewController:
                searchViewController.setSearchVisible(true, animated: false)
                searchViewController.searchTerm = info.searchTerm
                searchViewController.search()
            default:
                break
            }
        } else {
            switch (viewController.kind, viewController.info) {
            case (.random, let info?) :
                guard let articleURL = articleURL(from: info) else {
                    return
                }
                let randomArticleVC = WMFRandomArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: Theme.standard)
                pushOrPresent(randomArticleVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.article, let info?):
                guard let articleURL = articleURL(from: info) else {
                    return
                }
                let articleVC = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: Theme.standard)
                pushOrPresent(articleVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.themeableNavigationController, _):
                let themeableNavigationController = WMFThemeableNavigationController()
                pushOrPresent(themeableNavigationController, navigationController: navigationController, presentation: viewController.presentation)
                newNavigationController = themeableNavigationController
            case (.settings, _):
                let settingsVC = WMFSettingsViewController(dataStore: dataStore)
                pushOrPresent(settingsVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.account, _):
                let accountVC = AccountViewController()
                accountVC.dataStore = dataStore
                pushOrPresent(accountVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.talkPage, let info?):
                guard
                    let siteURLString = info.talkPageSiteURLString,
                    let siteURL = URL(string: siteURLString),
                    let title = info.talkPageTitle,
                    let typeRawValue = info.talkPageTypeRawValue,
                    let type = TalkPageType(rawValue: typeRawValue)
                else {
                    return
                }
                let talkPageContainerVC = TalkPageContainerViewController(title: title, siteURL: siteURL, type: type, dataStore: dataStore)
                talkPageContainerVC.apply(theme: Theme.standard)
                navigationController.isNavigationBarHidden = true
                navigationController.pushViewController(talkPageContainerVC, animated: false)
            case (.talkPageReplyList, let info?):
                guard
                    let talkPageTopic = managedObject(with: info.contentGroupIDURIString, in: moc) as? TalkPageTopic,
                    let talkPageContainerVC = navigationController.viewControllers.last as? TalkPageContainerViewController
                else {
                    return
                }
                talkPageContainerVC.pushToReplyThread(topic: talkPageTopic)
            case (.readingListDetail, let info?):
                guard let readingList = managedObject(with: info.readingListURIString, in: moc) as? ReadingList else {
                    return
                }
                let readingListDetailVC =  ReadingListDetailViewController(for: readingList, with: dataStore)
                pushOrPresent(readingListDetailVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.detail, let info?):
                guard
                    let contentGroup = managedObject(with: info.contentGroupIDURIString, in: moc) as? WMFContentGroup,
                    let detailVC = contentGroup.detailViewControllerWithDataStore(dataStore, theme: Theme.standard)
                else {
                    return
                }
                pushOrPresent(detailVC, navigationController: navigationController, presentation: viewController.presentation)
            default:
                return
            }
        }

        for child in viewController.children {
            restore(viewController: child, for: tabBarController, navigationController: newNavigationController ?? navigationController, in: moc)
        }
    }

    private func managedObject<T: NSManagedObject>(with uriString: String?, in moc: NSManagedObjectContext) -> T? {
        guard
            let uriString = uriString,
            let uri = URL(string: uriString),
            let id = moc.persistentStoreCoordinator?.managedObjectID(forURIRepresentation: uri),
            let object = try? moc.existingObject(with: id) as? T
        else {
            return nil
        }
        return object
    }

    func saveNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        var viewControllers = [ViewController]()
        for viewController in navigationController.viewControllers {
            viewControllers.append(contentsOf: viewControllersToSave(from: viewController, presentedVia: .push))
        }
        let navigationState = NavigationState(viewControllers: viewControllers)
        let encoder = PropertyListEncoder()
        let value = try? encoder.encode(navigationState) as NSData
        moc.wmf_setValue(value, forKey: key)
    }

    private func viewControllerToSave(from viewController: UIViewController, presentedVia presentation: Presentation) -> ViewController? {
        let kind: ViewController.Kind?
        let info: Info?

        switch viewController {
        case let tabBarController as UITabBarController:
            kind = .tab
            switch tabBarController.selectedViewController {
            case let savedViewController as SavedViewController:
                info = Info(selectedIndex: tabBarController.selectedIndex, currentSavedViewRawValue: savedViewController.currentView.rawValue)
            case let searchViewController as SearchViewController:
                info = Info(selectedIndex: tabBarController.selectedIndex, searchTerm: searchViewController.searchTerm)
            default:
                info = Info(selectedIndex: tabBarController.selectedIndex)
            }
        case let articleViewController as WMFArticleViewController:
            kind = viewController is WMFRandomArticleViewController ? .random : .article
            info = Info(articleKey: articleViewController.articleURL.wmf_articleDatabaseKey, articleSectionAnchor: articleViewController.visibleSectionAnchor)
        case let talkPageContainerVC as TalkPageContainerViewController:
            kind = .talkPage
            info = Info(talkPageSiteURLString: talkPageContainerVC.siteURL.absoluteString, talkPageTitle: talkPageContainerVC.talkPageTitle, talkPageTypeRawValue: talkPageContainerVC.type.rawValue)
        case let talkPageReplyListVC as TalkPageReplyListViewController:
            kind = .talkPageReplyList
            info = Info(talkPageTopicURIString: talkPageReplyListVC.topic.objectID.uriRepresentation().absoluteString)
        case let readingListDetailVC as ReadingListDetailViewController:
            kind = .readingListDetail
            info = Info(readingListURIString: readingListDetailVC.readingList.objectID.uriRepresentation().absoluteString)
        case let detailPresenting as DetailPresentingFromContentGroup:
            kind = .detail
            info = Info(contentGroupIDURIString: detailPresenting.contentGroupIDURIString)
        default:
            kind = nil
            info = nil
        }

        return ViewController(kind: kind, presentation: presentation, info: info)
    }

    private func viewControllersToSave(from viewController: UIViewController, presentedVia presentation: Presentation) -> [ViewController] {
        var viewControllers = [ViewController]()
        if var viewControllerToSave = viewControllerToSave(from: viewController, presentedVia: presentation) {
            if let presentedViewController = viewController.presentedViewController {
                viewControllerToSave.updateChildren(viewControllersToSave(from: presentedViewController, presentedVia: .modal))
            }
            if let navigationController = viewController as? UINavigationController {
                var children = [ViewController]()
                for viewController in navigationController.viewControllers {
                    children.append(contentsOf: viewControllersToSave(from: viewController, presentedVia: .push))
                }
                viewControllerToSave.updateChildren(children)
            }
            viewControllers.append(viewControllerToSave)
        }
        return viewControllers
    }
}
