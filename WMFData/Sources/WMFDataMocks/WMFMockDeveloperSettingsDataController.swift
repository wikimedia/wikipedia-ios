import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {
    var forceYiREntryPoint2026: Bool { return false }
    var forceYiRUserDataState: WMFYearInReviewDataController.YiRUserDataState? { return nil }
    var enableYearInReview: Bool { return true }
    var enableActivityTabs: Bool { return true }
    var enableArticleTabs: Bool { return true }
    var forceMaxArticleTabsTo5: Bool { return false }
    var enableHomeTab: Bool { return false }
    var enableHomeTabExperimentControl: Bool { return false }
    var enableHomeTabExperimentGroupB: Bool { return false }
    func transitionToEnrolledStateIfForced() {}

    private let featureConfig: WMFData.WMFFeatureConfigResponse

    public init(featureConfig: WMFData.WMFFeatureConfigResponse) {
        self.featureConfig = featureConfig
    }

    func loadFeatureConfig() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
