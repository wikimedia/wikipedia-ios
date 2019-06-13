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
            var info: Info?

            enum Kind: String, Codable {
                case explore
                case places
                case saved
                case history
                case search

                case article

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

                init?(key: String? = nil, index: Int? = nil) {
                    if key == nil, index == nil {
                        return nil
                    } else {
                        self.key = key
                        self.index = index
                    }
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
            switch (viewController.kind, viewController.info) {
            case (let kind, let info?) where kind.isTab:
                guard let index = info.index else {
                    assertionFailure("View controllers in UITabController should have an associated index")
                    continue
                }
                tabBarController.selectedIndex = index
            case (.article, let info?):
                guard let key = info.key else {
                    assertionFailure("Article view controllers should have an associated key")
                    continue
                }
                guard let articleURL = URLComponents(string: key)?.url else {
                    continue
                }
                let articleViewController = WMFArticleViewController(articleURL: articleURL, dataStore: dataStore, theme: Theme.standard)
                navigationController.pushViewController(articleViewController, animated: false)
            default:
                continue
            }
        }
    }

    func saveNavigationState(for navigationController: UINavigationController, in moc: NSManagedObjectContext) {
        assert(Thread.isMainThread, "Saving navigation state should be performed on the main thread")
        var viewControllers = [ViewController]()
        for viewController in navigationController.viewControllers {
            let title: String?
            let key: String?
            let index: Int?
            switch viewController {
            case let tabBarController as UITabBarController:
                title = tabBarController.selectedViewController?.title?.lowercased()
                key = nil
                index = tabBarController.selectedIndex
            case let articleViewController as WMFArticleViewController:
                title = "article"
                // This has to happen after ArticleViewController sets articleURLWithFragment
                let articleURL = articleViewController.articleURLWithFragment ?? articleViewController.articleURL
                key = articleURL.wmf_articleDatabaseKey
                index = nil
            default:
                assertionFailure("Unhandled viewController type")
                title = nil
                key = nil
                index = nil
            }
            if let title = title, let kind = ViewController.Kind(from: title) {
                assert(kind.isTab ? index != nil : true, "View controllers in UITabController should have an associated index")
                viewControllers.append(ViewController(kind: kind, info: ViewController.Info(key: key, index: index)))
            }
        }
        let navigationState = NavigationState(viewControllers: viewControllers)
        let encoder = PropertyListEncoder()
        let value = try? encoder.encode(navigationState) as NSData
        moc.wmf_setValue(value, forKey: key)
    }
}
