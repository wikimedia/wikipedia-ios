import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {
    
    private let featureConfig: WMFData.WMFFeatureConfigResponse
    
    public init(featureConfig: WMFData.WMFFeatureConfigResponse) {
        self.featureConfig = featureConfig
    }
    
    func loadFeatureConfig() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
