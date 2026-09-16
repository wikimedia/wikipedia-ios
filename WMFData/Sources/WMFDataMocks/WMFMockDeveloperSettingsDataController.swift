import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {

    var enableYearInReview: Bool { return true }
    var enableActivityTabs: Bool { return true }
    var enableArticleTabs: Bool { return true }
    var forceMaxArticleTabsTo5: Bool { return false }
    var enableHomeTab: Bool { return false }
    var showYiR2025: Bool { return true }
    var showYiR2026: Bool { return showYiR2026Override }
    var showYiR2026Announcement: Bool { return showYiR2026AnnouncementOverride }
    var enableYiRLoginExperimentControl: Bool { return false }
    var enableYiRLoginExperimentB: Bool { return false }
    var enableHomeTabExperimentControl: Bool { return false }
    var enableHomeTabExperimentGroupB: Bool { return false }
    func transitionToEnrolledStateIfForced() {}

    /// Defaults to false so tests exercise the real date window and the real once-per-user gate.
    /// Set either one in a test that needs the developer override path.
    var showYiR2026Override: Bool
    var showYiR2026AnnouncementOverride: Bool

    private let featureConfig: WMFData.WMFFeatureConfigResponse

    public init(featureConfig: WMFData.WMFFeatureConfigResponse, showYiR2026: Bool = false, showYiR2026Announcement: Bool = false) {
        self.featureConfig = featureConfig
        self.showYiR2026Override = showYiR2026
        self.showYiR2026AnnouncementOverride = showYiR2026Announcement
    }

    func loadFeatureConfig() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
