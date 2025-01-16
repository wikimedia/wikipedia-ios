import Foundation
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let enableAltTextExperimentForEN: String
    let alwaysShowAltTextEntryPoint: String
    let sendAnalyticsToWMFLabs: String
    let enableYearinReview: String
    let bypassDonation: String
    let close: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, enableAltTextExperimentForEN: String, alwaysShowAltTextEntryPoint: String, sendAnalyticsToWMFLabs: String, enableYearinReview: String, bypassDonation: String, close: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.enableAltTextExperimentForEN = enableAltTextExperimentForEN
        self.alwaysShowAltTextEntryPoint = alwaysShowAltTextEntryPoint
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.enableYearinReview = enableYearinReview
        self.bypassDonation = bypassDonation
        self.close = close
    }
}

@objc public class WMFDeveloperSettingsViewModel: NSObject {
    
    let localizedStrings: WMFDeveloperSettingsLocalizedStrings
    let formViewModel: WMFFormViewModel
    
    private var subscribers: Set<AnyCancellable> = []
    
    @objc public init(localizedStrings: WMFDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings
        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
        let enableAltTextExperimentItemForENItem = WMFFormItemSelectViewModel(title: localizedStrings.enableAltTextExperimentForEN, isSelected: WMFDeveloperSettingsDataController.shared.enableAltTextExperimentForEN)
        let alwaysShowAltTextEntryPointItem = WMFFormItemSelectViewModel(title: localizedStrings.alwaysShowAltTextEntryPoint, isSelected: WMFDeveloperSettingsDataController.shared.alwaysShowAltTextEntryPoint)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)

        let bypassDonationItem = WMFFormItemSelectViewModel(title: localizedStrings.bypassDonation, isSelected: WMFDeveloperSettingsDataController.shared.bypassDonation)

        formViewModel = WMFFormViewModel(sections: [WMFFormSectionSelectViewModel(items: [doNotPostImageRecommendationsEditItem, enableAltTextExperimentItemForENItem, alwaysShowAltTextEntryPointItem, sendAnalyticsToWMFLabsItem, bypassDonationItem], selectType: .multi)])

        doNotPostImageRecommendationsEditItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit = isSelected
        }.store(in: &subscribers)
        
        enableAltTextExperimentItemForENItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableAltTextExperimentForEN = isSelected
        }.store(in: &subscribers)
        
        alwaysShowAltTextEntryPointItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.alwaysShowAltTextEntryPoint = isSelected
        }.store(in: &subscribers)
        
        sendAnalyticsToWMFLabsItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs = isSelected
        }.store(in: &subscribers)

        bypassDonationItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.bypassDonation = isSelected
        }.store(in: &subscribers)
    }

}
