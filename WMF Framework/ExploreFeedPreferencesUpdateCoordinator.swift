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
        feedContentController.saveNewExploreFeedPreferences(newExploreFeedPreferences, updateFeed: true) // TODO: add conditions
    }
}
