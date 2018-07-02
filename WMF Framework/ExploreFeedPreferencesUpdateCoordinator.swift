@objc public class ExploreFeedPreferencesUpdateCoordinator: NSObject {
    private let feedContentController: WMFExploreFeedContentController
    private var oldExploreFeedPreferences = Dictionary<String, Any>()
    private var newExploreFeedPreferences = Dictionary<String, Any>()
    private var willTurnOnContentGroupOrLanguage = false

    @objc public init(feedContentController: WMFExploreFeedContentController) {
        self.feedContentController = feedContentController
    }

    @objc public func configure(oldExploreFeedPreferences: Dictionary<String, Any>, newExploreFeedPreferences: Dictionary<String, Any>, willTurnOnContentGroupOrLanguage: Bool) {
        self.oldExploreFeedPreferences = oldExploreFeedPreferences
        self.newExploreFeedPreferences = newExploreFeedPreferences
        self.willTurnOnContentGroupOrLanguage = willTurnOnContentGroupOrLanguage
    }

    @objc public func coordinateUpdate(from viewController: UIViewController) {
        guard !willTurnOnContentGroupOrLanguage else {
            feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, updateFeed: true)
            return
        }
        guard UserDefaults.wmf_userDefaults().defaultTabType == .explore else {
            feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, updateFeed: true)
            return
        }
        guard newExploreFeedPreferences.count == 1 else {
            feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, updateFeed: true)
            return
        }
        let alertController = UIAlertController(title: "Turn off Explore feed tab?", message: "Turning off all feed cards will result in turning off the Explore feed tab.", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "Turn off Explore feed", style: .destructive, handler: { (_) in
            self.feedContentController.saveNewExploreFeedPreferences(self.newExploreFeedPreferences, updateFeed: true)
            UserDefaults.wmf_userDefaults().defaultTabType = .settings
        }))
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel))
        if let presenter = viewController.presentedViewController {
            assert(presenter is UINavigationController) // TODO: remove assertion, find a fallback
            presenter.present(alertController, animated: true)
        } else {
            viewController.present(alertController, animated: true)
        }
    }
}
