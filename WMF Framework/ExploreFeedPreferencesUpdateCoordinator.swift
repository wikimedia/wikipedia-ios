@objc public class ExploreFeedPreferencesUpdateCoordinator: NSObject {
    private unowned let feedContentController: WMFExploreFeedContentController
    private var oldExploreFeedPreferences = [String: Any]()
    private var newExploreFeedPreferences = [String: Any]()
    private var willTurnOnContentGroupOrLanguage = false
    private var updateFeed: Bool = true

    @objc public init(feedContentController: WMFExploreFeedContentController) {
        self.feedContentController = feedContentController
    }

    @objc public func configure(oldExploreFeedPreferences: [String: Any], newExploreFeedPreferences: [String: Any], willTurnOnContentGroupOrLanguage: Bool, updateFeed: Bool) {
        self.oldExploreFeedPreferences = oldExploreFeedPreferences
        self.newExploreFeedPreferences = newExploreFeedPreferences
        self.willTurnOnContentGroupOrLanguage = willTurnOnContentGroupOrLanguage
        self.updateFeed = updateFeed
    }

    @objc public func coordinateUpdate(from viewController: UIViewController) {
        if willTurnOnContentGroupOrLanguage {
            guard UserDefaults.standard.defaultTabType == .settings else {
                feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
                return
            }
            guard areAllLanguagesTurnedOff(in: oldExploreFeedPreferences) else {
                feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
                return
            }
            guard areGlobalCardsTurnedOff(in: oldExploreFeedPreferences) else {
                feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
                return
            }
            present(turnOnExploreAlertController, from: viewController)
        } else {
            guard UserDefaults.standard.defaultTabType == .explore else {
                feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
                return
            }
            guard areAllLanguagesTurnedOff(in: newExploreFeedPreferences) else {
                feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
                return
            }
            guard areGlobalCardsTurnedOff(in: newExploreFeedPreferences) else {
                feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
                return
            }
            present(turnOffExploreAlertController, from: viewController)
        }
    }

    private lazy var turnOffExploreAlertController: UIAlertController = {
        let alertController = UIAlertController(title: WMFLocalizedString("explore-feed-preferences-turn-off-explore-feed-alert-title", value: "Turn off Explore feed?", comment: "Title for alert that allows user to decide whether they want to turn off Explore feed"), message: WMFLocalizedString("explore-feed-preferences-turn-off-explore-feed-alert-message", value: "Hiding all Explore feed cards will turn off the Explore tab and replace it with a Settings tab", comment: "Message for alert that allows user to decide whether they want to turn off Explore feed"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: WMFLocalizedString("explore-feed-preferences-turn-off-explore-feed-alert-action-title", value: "Turn off Explore feed", comment: "Title for action alert that allows user to turn off Explore feed"), style: .destructive, handler: { _ in
            UserDefaults.standard.defaultTabType = .settings
            self.feedContentController.saveNewExploreFeedPreferences(self.newExploreFeedPreferences, apply: true, updateFeed: self.updateFeed)
        }))
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in
            self.feedContentController.rejectNewExploreFeedPreferences()
        }))
        return alertController
    }()

    private lazy var turnOnExploreAlertController: UIAlertController = {
        let alertController = UIAlertController(title: CommonStrings.turnOnExploreTabTitle, message: WMFLocalizedString("explore-feed-preferences-turn-on-explore-feed-alert-message", value: "By choosing to show Explore feed cards you are turning on the Explore tab", comment: "Message for alert that allows user to decide whether they want to turn on Explore feed"), preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: CommonStrings.turnOnExploreActionTitle, style: .default, handler: { _ in
            self.feedContentController.saveNewExploreFeedPreferences(self.newExploreFeedPreferences, apply: true, updateFeed: self.updateFeed)
            UserDefaults.standard.defaultTabType = .explore
        }))
        alertController.addAction(UIAlertAction(title: CommonStrings.cancelActionTitle, style: .cancel, handler: { _ in
            self.feedContentController.rejectNewExploreFeedPreferences()
        }))
        return alertController
    }()

    private func present(_ alertController: UIAlertController, from presenter: UIViewController) {
        if let presenter = presenter.presentedViewController {
            if presenter is UINavigationController {
                presenter.present(alertController, animated: true)
            }
        } else {
            presenter.present(alertController, animated: true)
        }
    }

    private func areAllLanguagesTurnedOff(in exploreFeedPreferences: [String: Any]) -> Bool {
        guard exploreFeedPreferences.count == 1 else {
            return false
        }
        guard exploreFeedPreferences.first?.key == WMFExploreFeedPreferencesGlobalCardsKey else {
            assertionFailure("Expected value with key WMFExploreFeedPreferencesGlobalCardsKey")
            return false
        }
        return true
    }

    private func globalCardPreferences(in exploreFeedPreferences: [String: Any]) -> [NSNumber: NSNumber]? {
        guard let globalCardPreferences = exploreFeedPreferences[WMFExploreFeedPreferencesGlobalCardsKey] as? [NSNumber: NSNumber] else {
            assertionFailure("Expected value of type Dictionary<NSNumber, NSNumber>")
            return nil
        }
        return globalCardPreferences
    }

    private func areGlobalCardsTurnedOff(in exploreFeedPreferences: [String: Any]) -> Bool {
        guard let globalCardPreferences = globalCardPreferences(in: exploreFeedPreferences) else {
            return false
        }
        return globalCardPreferences.values.filter { $0.boolValue == true }.isEmpty
    }
}
