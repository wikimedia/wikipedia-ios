@objcMembers final class NavigationStateController: NSObject {
    private let key = "nav_state"
    private let dataStore: MWKDataStore

    init(dataStore: MWKDataStore) {
        self.dataStore = dataStore
        super.init()
    }

    private typealias ViewController = NavigationState.ViewController

    private struct NavigationState: Codable {
        var viewControllers: [ViewController]

        struct ViewController: Codable {
            var kind: Kind
            var info: Info
            var children: [ViewController]

            mutating func updateChildren(_ children: [ViewController]) {
                self.children = children
            }

            enum Kind: String, Codable {
                case explore
                case places
                case saved
                case history
                case search

                case article
                case themeableNavigationController
                case settings

                case account

                init?(from rawValue: String?) {
                    guard let rawValue = rawValue else {
                        return nil
                    }
                    self.init(rawValue: rawValue)
                }

                var isTab: Bool {
                    switch self {
                    case .explore:
                        fallthrough
                    case .places:
                        fallthrough
                    case .saved:
                        fallthrough
                    case .history:
                        fallthrough
                    case .search:
                        return true
                    default:
                        return false
                    }
                }
            }

            struct Info: Codable {
                var key: String?
                var index: Int?
                var presentation: Presentation

                enum Presentation: Int, Codable {
                    case push
                    case modal
                }
            }
        }
    }

    func restoreNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        assert(Thread.isMainThread, "Restoring navigation state should be performed on the main thread")
        guard let tabBarController = navigationController.viewControllers.first as? UITabBarController else {
            assertionFailure("Expected root view controller to be UITabBarController")
            return
        }
        let keyValue = moc.wmf_keyValue(forKey: key)
        guard let value = keyValue?.value as? Data else {
            return
        }
        let decoder = PropertyListDecoder()
        guard let navigationState = try? decoder.decode(NavigationState.self, from: value) else {
            return
        }
        for viewController in navigationState.viewControllers {
            restore(viewController: viewController, for: tabBarController, navigationController: navigationController)
        }
    }

    private func restore(viewController: ViewController, for tabBarController: UITabBarController, navigationController: UINavigationController) {
        var newNavigationController: UINavigationController?
        switch (viewController.kind) {
        case let kind where kind.isTab:
            guard let index = viewController.info.index else {
                assertionFailure("View controllers in UITabController should have an associated index")
                return
            }
            tabBarController.selectedIndex = index
        case .article:
            guard let key = viewController.info.key else {
                assertionFailure("Article view controllers should have an associated key")
                return
            }
            guard let articleURL = URLComponents(string: key)?.url else {
                return
            }
            let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: Theme.standard)
            navigationController.pushViewController(articleViewController, animated: false)
        case .themeableNavigationController:
            let themeableNavigationController = WMFThemeableNavigationController()
            if viewController.info.presentation == .modal {
                navigationController.present(themeableNavigationController, animated: false)
            } else {
                navigationController.pushViewController(themeableNavigationController, animated: false)
            }
            newNavigationController = themeableNavigationController
        case .settings:
            let settingsVC = WMFSettingsViewController(dataStore: dataStore)
            navigationController.pushViewController(settingsVC, animated: false)
        case .account:
            WMFAuthenticationManager.sharedInstance.attemptLogin {
                let accountVC = AccountViewController()
                accountVC.dataStore = self.dataStore
                navigationController.pushViewController(accountVC, animated: false)
            }
        default:
            assertionFailure()
            return
        }
        for child in viewController.children {
            restore(viewController: child, for: tabBarController, navigationController: newNavigationController ?? navigationController)
        }
    }

    func saveNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        assert(Thread.isMainThread, "Saving navigation state should be performed on the main thread")
        var viewControllers = [ViewController]()
        for viewController in navigationController.viewControllers {
            viewControllers.append(contentsOf: viewControllersToSave(from: viewController, presentedVia: .push))
        }
        let navigationState = NavigationState(viewControllers: viewControllers)
        let encoder = PropertyListEncoder()
        let value = try? encoder.encode(navigationState) as NSData
        moc.wmf_setValue(value, forKey: key)
    }

    private func viewControllerToSave(from viewController: UIViewController, presentedVia presentation: ViewController.Info.Presentation) -> ViewController? {
        let kind: ViewController.Kind?
        let key: String?
        let index: Int?

        switch viewController {
        case let tabBarController as UITabBarController:
            kind = ViewController.Kind(from: tabBarController.selectedViewController?.title?.lowercased())
            key = nil
            index = tabBarController.selectedIndex
        case let articleViewController as WMFArticleViewController:
            kind = .article
            // This has to happen after ArticleViewController sets articleURLWithFragment
            let articleURL = articleViewController.articleURLWithFragment ?? articleViewController.articleURL
            key = articleURL.wmf_articleDatabaseKey
            index = nil
        case is WMFThemeableNavigationController:
            kind = .themeableNavigationController
            key = nil
            index = nil
        case is WMFSettingsViewController:
            kind = .settings
            key = nil
            index = nil
        case is AccountViewController:
            kind = .account
            key = nil
            index = nil
        default:
            assertionFailure("Unhandled viewController type")
            kind = nil
            key = nil
            index = nil
        }
        if let kind = kind {
            assert(kind.isTab ? index != nil : true, "View controllers in UITabController should have an associated index")
            return ViewController(kind: kind, info: ViewController.Info(key: key, index: index, presentation: presentation), children: [])
        } else {
            return nil
        }
    }

    private func viewControllersToSave(from viewController: UIViewController, presentedVia presentation: ViewController.Info.Presentation) -> [ViewController] {
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
