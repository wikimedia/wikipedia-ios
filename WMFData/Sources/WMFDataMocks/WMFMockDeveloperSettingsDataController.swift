import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {

    var enableYearInReview: Bool {
        return true
    }
    
    var enableActivityTabs: Bool {
        return true
    }
    
    var enableArticleTabs: Bool {
        return true
    }
    
    var forceMaxArticleTabsTo5: Bool {
        return false
    }
    
    var enableMoreDynamicTabsV2GroupB: Bool {
        get {
            return true
        }
    }

    var enableMoreDynamicTabsV2GroupC: Bool {
        get {
            return false
        }
    }
    
    var showYiRV2: Bool { return false }
    
    var showYiRV3: Bool { return true }

    private let featureConfig: WMFData.WMFFeatureConfigResponse
    
    public init(featureConfig: WMFData.WMFFeatureConfigResponse) {
        self.featureConfig = featureConfig
    }
    
    func loadFeatureConfig() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
