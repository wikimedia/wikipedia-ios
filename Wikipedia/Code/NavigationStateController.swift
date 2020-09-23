import WMF

protocol DetailPresentingFromContentGroup {
    var contentGroupIDURIString: String? { get }
}

@objc(WMFNavigationStateController)
final class NavigationStateController: NSObject {
    private let dataStore: MWKDataStore
    private var theme = Theme.standard

    @objc init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }

    private typealias ViewController = NavigationState.ViewController
    private typealias Presentation = ViewController.Presentation
    private typealias Info = ViewController.Info

    @objc func restoreNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext, with theme: Theme, completion: @escaping () -> Void) {
        guard let tabBarController = navigationController.viewControllers.first as? UITabBarController else {
            assertionFailure("Expected root view controller to be UITabBarController")
            completion()
            return
        }
        guard let navigationState = moc.navigationState else {
            completion()
            return
        }
        self.theme = theme
        let restore = {
            completion()
            for viewController in navigationState.viewControllers {
                self.restore(viewController: viewController, for: tabBarController, navigationController: navigationController, in: moc)
            }
        }
        if navigationState.shouldAttemptLogin {
            dataStore.authenticationManager.attemptLogin {
                restore()
            }
        } else {
            restore()
        }
    }

    func allPreservedArticleKeys(in moc: NSManagedObjectContext) -> [String]? {
        return moc.navigationState?.viewControllers.compactMap { $0.info?.articleKey }
    }

    private func pushOrPresent(_ viewController: UIViewController & Themeable, navigationController: UINavigationController, presentation: Presentation, animated: Bool = false) {
        viewController.apply(theme: theme)
        switch presentation {
        case .push:
            navigationController.pushViewController(viewController, animated: animated)
        case .modal:
            viewController.modalPresentationStyle = .overFullScreen
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
                searchViewController.searchAndMakeResultsVisibleForSearchTerm(info.searchTerm, animated: false)
            case let exploreViewController as ExploreViewController:
                exploreViewController.presentedContentGroupKey = info.presentedContentGroupKey
                exploreViewController.shouldRestoreScrollPosition = true
            default:
                break
            }
        } else {
            switch (viewController.kind, viewController.info) {
            case (.random, let info?) :
                guard
                    let articleURL = articleURL(from: info),
                    let randomArticleVC = RandomArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme)
                else {
                    return
                }
                pushOrPresent(randomArticleVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.article, let info?):
                guard let articleURL = articleURL(from: info) else {
                    return
                }
                guard let articleVC = ArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: theme) else {
                    return
                }
                articleVC.isRestoringState = true
                // never present an article modal, the nav bar disappears
                pushOrPresent(articleVC, navigationController: navigationController, presentation: .push)
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
                
                let talkPageContainer = TalkPageContainerViewController.talkPageContainer(title: title, siteURL: siteURL, type: type, dataStore: dataStore, theme: theme)
                navigationController.isNavigationBarHidden = true
                navigationController.pushViewController(talkPageContainer, animated: false)
            case (.talkPageReplyList, let info?):
                guard
                    let talkPageTopic = managedObject(with: info.contentGroupIDURIString, in: moc) as? TalkPageTopic,
                    let talkPageContainerVC = navigationController.viewControllers.last as? TalkPageContainerViewController
                else {
                    return
                }
                talkPageContainerVC.pushToReplyThread(topic: talkPageTopic, animated: false)
            case (.readingListDetail, let info?):
                guard let readingList = managedObject(with: info.readingListURIString, in: moc) as? ReadingList else {
                    return
                }
                let readingListDetailVC =  ReadingListDetailViewController(for: readingList, with: dataStore)
                pushOrPresent(readingListDetailVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.detail, let info?):
                guard
                    let contentGroup = managedObject(with: info.contentGroupIDURIString, in: moc) as? WMFContentGroup,
                    let detailVC = contentGroup.detailViewControllerWithDataStore(dataStore, theme: theme) as? UIViewController & Themeable
                else {
                    return
                }
                if let onThisDayVC = detailVC as? OnThisDayViewController, let shouldShowNavigationBar = viewController.info?.shouldShowNavigationBar {
                    onThisDayVC.shouldShowNavigationBar = shouldShowNavigationBar
                }
                pushOrPresent(detailVC, navigationController: navigationController, presentation: viewController.presentation)
            case (.singleWebPage, let info):
                guard let url = info?.url else {
                    return
                }
                pushOrPresent(SinglePageWebViewController(url: url, theme: theme), navigationController: navigationController, presentation: .push)
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

    var shouldAttemptLogin: Bool = false

    @objc func saveNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        var viewControllers = [ViewController]()
        shouldAttemptLogin = false
        for viewController in navigationController.viewControllers {
            viewControllers.append(contentsOf: viewControllersToSave(from: viewController, presentedVia: .push))
        }
        moc.navigationState = NavigationState(viewControllers: viewControllers, shouldAttemptLogin: shouldAttemptLogin)
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
            case let exploreViewController as ExploreViewController:
                info = Info(selectedIndex: tabBarController.selectedIndex, presentedContentGroupKey: exploreViewController.presentedContentGroupKey)
            default:
                info = Info(selectedIndex: tabBarController.selectedIndex)
            }
        case is WMFThemeableNavigationController:
            kind = .themeableNavigationController
            info = nil
        case is WMFSettingsViewController:
            kind = .settings
            info = nil
        case is AccountViewController:
            kind = .account
            info = nil
            shouldAttemptLogin = true
        case let talkPageContainerVC as TalkPageContainerViewController:
            let result = determineKindInfoForArticleOrTalk(obj: talkPageContainerVC)
            kind = result.kind
            info = result.info
        case let talkPageReplyListVC as TalkPageReplyListViewController:
            kind = .talkPageReplyList
            info = Info(contentGroupIDURIString: talkPageReplyListVC.topic.objectID.uriRepresentation().absoluteString)
        case let readingListDetailVC as ReadingListDetailViewController:
            kind = .readingListDetail
            info = Info(readingListURIString: readingListDetailVC.readingList.objectID.uriRepresentation().absoluteString)
        case let detailPresenting as DetailPresentingFromContentGroup:
            kind = .detail
            let shouldShowNavigationBar = (viewController as? OnThisDayViewController)?.shouldShowNavigationBar
            info = Info(shouldShowNavigationBar: shouldShowNavigationBar, contentGroupIDURIString: detailPresenting.contentGroupIDURIString)
        case let singlePageWebViewController as SinglePageWebViewController:
            kind = .singleWebPage
            info = Info(url: singlePageWebViewController.url)
        default:
            let result = determineKindInfoForArticleOrTalk(obj: viewController)
            kind = result.kind
            info = result.info
        }

        return ViewController(kind: kind, presentation: presentation, info: info)
    }
    
    private func determineKindInfoForArticleOrTalk(obj: Any) -> (kind: ViewController.Kind?, info: Info?) {
        
        let kind: ViewController.Kind?
        let info: Info?
        switch obj {
            case let articleViewController as ArticleViewController:
                kind = obj is RandomArticleViewController ? .random : .article
                info = Info(articleKey: articleViewController.articleURL.wmf_databaseKey)
            case let talkPageContainerVC as TalkPageContainerViewController:
                kind = .talkPage
                info = Info(talkPageSiteURLString: talkPageContainerVC.siteURL.absoluteString, talkPageTitle: talkPageContainerVC.talkPageTitle, talkPageTypeRawValue: talkPageContainerVC.type.rawValue)
        default:
            kind = nil
            info = nil
        }
        
        return (kind: kind, info: info)
    }

    private func viewControllersToSave(from viewController: UIViewController, presentedVia presentation: Presentation) -> [ViewController] {
        var viewControllers = [ViewController]()
        var append = true
        if var viewControllerToSave = viewControllerToSave(from: viewController, presentedVia: presentation) {
            if let presentedViewController = viewController.presentedViewController {
                viewControllerToSave.updateChildren(viewControllersToSave(from: presentedViewController, presentedVia: .modal))
            }
            if let navigationController = viewController as? UINavigationController {
                var children = [ViewController]()
                for viewController in navigationController.viewControllers {
                    children.append(contentsOf: viewControllersToSave(from: viewController, presentedVia: .push))
                }
                append = !children.isEmpty
                viewControllerToSave.updateChildren(children)
            }
            if append {
                viewControllers.append(viewControllerToSave)
            }
        }
        return viewControllers
    }
}
