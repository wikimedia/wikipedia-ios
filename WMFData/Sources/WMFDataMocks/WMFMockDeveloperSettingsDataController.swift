import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {
    var forceYiRDataState: WMFYearInReviewDataController.YiRDataState? { return nil }
    var forceYiRSlidesExperience: WMFYearInReviewDataController.YiRForcedSlidesExperience? { return nil }
    var enableYearInReview: Bool { return true }
    var enableActivityTabs: Bool { return true }
    var enableArticleTabs: Bool { return true }
    var forceMaxArticleTabsTo5: Bool { return false }
    var forceYiREntryPoint2026: Bool { return forceYiR2026Override }
    var forceYiR2026Announcement: Bool { return forceYiR2026AnnouncementOverride }
    func transitionToEnrolledStateIfForced() {}

    /// Defaults to false so tests exercise the real date window and the real once-per-user gate.
    /// Set either one in a test that needs the developer override path.
    let forceYiR2026Override: Bool
    let forceYiR2026AnnouncementOverride: Bool

    private let featureConfig: WMFData.WMFFeatureConfigResponse

    public init(featureConfig: WMFData.WMFFeatureConfigResponse, forceYiR2026: Bool = false, forceYiR2026Announcement: Bool = false) {
        self.featureConfig = featureConfig
        self.forceYiR2026Override = forceYiR2026
        self.forceYiR2026AnnouncementOverride = forceYiR2026Announcement
    }

    func loadFeatureConfig() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
