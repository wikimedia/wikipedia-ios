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
        guard let globalCardPreferences = newExploreFeedPreferences.first?.value as? Dictionary<NSNumber, NSNumber> else {
            assertionFailure("Expected value of type Dictionary<NSNumber, NSNumber>")
            return
        }
        let willTurnOffGlobalCards = globalCardPreferences.values.filter { $0.boolValue == true }.isEmpty
        guard willTurnOffGlobalCards else {
            feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, updateFeed: true)
            return
        }
        let alertController = UIAlertController(title: WMFLocalizedString("explore-feed-preferences-turn-off-explore-feed-alert-title", value: "Turn off Explore feed?", comment: "Title for alert that allows user to decide whether they want to turn off Explore feed"), message: "Hiding all Explore feed cards will turn off the Explore tab and replace it with a Settings tab", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-turn-off-explore-feed-alert-action-title", value: "Turn off Explore feed", comment: "Title for action alert that allows user to turn off Explore feed"), style: .destructive, handler: { (_) in
            UserDefaults.wmf_userDefaults().defaultTabType = .settings
            self.feedContentController.saveNewExploreFeedPreferences(self.newExploreFeedPreferences, updateFeed: true)
        }))
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { (_) in
            self.feedContentController.rejectNewExploreFeedPreferences()
        }))
        if let presenter = viewController.presentedViewController {
            if presenter is UINavigationController {
                presenter.present(alertController, animated: true)
            }
        } else {
            viewController.present(alertController, animated: true)
        }
    }
}
