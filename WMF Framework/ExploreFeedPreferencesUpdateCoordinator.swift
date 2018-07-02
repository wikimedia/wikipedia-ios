@objc public class ExploreFeedPreferencesUpdateCoordinator: NSObject {
    private let feedContentController: WMFExploreFeedContentController

    @objc public init(feedContentController: WMFExploreFeedContentController) {
        self.feedContentController = feedContentController
    }
}
