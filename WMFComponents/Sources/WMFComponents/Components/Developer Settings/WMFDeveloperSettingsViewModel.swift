import Foundation
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let enableAltTextExperiment: String
    let enableAltTextExperimentForEN: String
    let setAltTextExperimentPercentage100: String
    let sendAnalyticsToWMFLabs: String
    let close: String
    
    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, enableAltTextExperiment: String, enableAltTextExperimentForEN: String, setAltTextExperimentPercentage100: String, sendAnalyticsToWMFLabs: String, close: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.enableAltTextExperiment = enableAltTextExperiment
        self.enableAltTextExperimentForEN = enableAltTextExperimentForEN
        self.setAltTextExperimentPercentage100 = setAltTextExperimentPercentage100
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
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
        let enableAltTextExperimentItem = WMFFormItemSelectViewModel(title: localizedStrings.enableAltTextExperiment, isSelected: WMFDeveloperSettingsDataController.shared.enableAltTextExperiment)
        let enableAltTextExperimentItemForENItem = WMFFormItemSelectViewModel(title: localizedStrings.enableAltTextExperimentForEN, isSelected: WMFDeveloperSettingsDataController.shared.enableAltTextExperimentForEN)
        let setAltTextExperimentPercentage100Item = WMFFormItemSelectViewModel(title: localizedStrings.setAltTextExperimentPercentage100, isSelected: WMFDeveloperSettingsDataController.shared.setAltTextExperimentPercentage100)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)

        formViewModel = WMFFormViewModel(sections: [WMFFormSectionSelectViewModel(items: [doNotPostImageRecommendationsEditItem, enableAltTextExperimentItem, enableAltTextExperimentItemForENItem, setAltTextExperimentPercentage100Item, sendAnalyticsToWMFLabsItem], selectType: .multi)])

        doNotPostImageRecommendationsEditItem.$isSelected.sink { isSelected in

            WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit = isSelected

        }.store(in: &subscribers)

        enableAltTextExperimentItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableAltTextExperiment = isSelected
        }.store(in: &subscribers)
        
        enableAltTextExperimentItemForENItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableAltTextExperimentForEN = isSelected
        }.store(in: &subscribers)
        
        setAltTextExperimentPercentage100Item.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.setAltTextExperimentPercentage100 = isSelected
        }.store(in: &subscribers)
        
        sendAnalyticsToWMFLabsItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs = isSelected
        }.store(in: &subscribers)

    }

}
