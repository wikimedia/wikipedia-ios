import WMFData

@objc public class ExploreFeedPreferencesUpdateCoordinator: NSObject {
    private unowned let feedContentController: WMFExploreFeedContentController
    private var newExploreFeedPreferences = [String: Any]()
    private var updateFeed: Bool = true

    @objc public init(feedContentController: WMFExploreFeedContentController) {
        self.feedContentController = feedContentController
    }

    @objc public func configure(oldExploreFeedPreferences: [String: Any], newExploreFeedPreferences: [String: Any], willTurnOnContentGroupOrLanguage: Bool, updateFeed: Bool) {
        self.newExploreFeedPreferences = newExploreFeedPreferences
        self.updateFeed = updateFeed
    }

    // Home is always the main tab, so hiding every card no longer turns Explore off and
    // showing a card no longer turns it on. There are no alerts to show: save directly.
    @objc public func coordinateUpdate(from viewController: UIViewController) {
        feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, apply: true, updateFeed: updateFeed)
    }
}
