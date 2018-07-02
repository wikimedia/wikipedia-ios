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

}
