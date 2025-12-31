import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {

    var enableMoreDynamicTabsV2GroupCSyncBridge: Bool { false }
    var enableYiRLoginExperimentControlSyncBridge: Bool { true }
    var enableYiRLoginExperimentBSyncBridge: Bool { true }
    var forceActivityTabControlSyncBridge: Bool { false }
    var forceActivityTabExperimentSyncBridge: Bool { false }

    var showYiRV3SyncBridge: Bool {
        return true
    }

    var showActivityTabSyncBridge: Bool {
        return true
    }

    var forceMaxArticleTabsTo5SyncBridge: Bool {
        return false
    }

    private let featureConfig: WMFData.WMFFeatureConfigResponse

    public init(featureConfig: WMFData.WMFFeatureConfigResponse) {
        self.featureConfig = featureConfig
    }

    func loadFeatureConfigSyncBridge() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
