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
    let done: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, enableAltTextExperimentForEN: String, alwaysShowAltTextEntryPoint: String, sendAnalyticsToWMFLabs: String, enableYearinReview: String, bypassDonation: String, close: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.enableAltTextExperimentForEN = enableAltTextExperimentForEN
        self.alwaysShowAltTextEntryPoint = alwaysShowAltTextEntryPoint
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.enableYearinReview = enableYearinReview
        self.bypassDonation = bypassDonation
        self.done = close
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
        
        let tabsPreserveRabbitHoleItem = WMFFormItemSelectViewModel(title: "Tabs - Preserve Rabbit Hole", isSelected: WMFDeveloperSettingsDataController.shared.tabsPreserveRabbitHole)
        
        let tabsDeepLinkInNewTabItem = WMFFormItemSelectViewModel(title: "Tabs - Deep Link In New Tab", isSelected: WMFDeveloperSettingsDataController.shared.tabsDeepLinkInNewTab)
        
        let tabsBackUnwindsArticleStackItem = WMFFormItemSelectViewModel(title: "Tabs - Back Unwinds Article Stack", isSelected: WMFDeveloperSettingsDataController.shared.tabsBackUnwindsArticleStack)

        formViewModel = WMFFormViewModel(sections: [WMFFormSectionSelectViewModel(items: [doNotPostImageRecommendationsEditItem, enableAltTextExperimentItemForENItem, alwaysShowAltTextEntryPointItem, sendAnalyticsToWMFLabsItem, bypassDonationItem, tabsPreserveRabbitHoleItem, tabsDeepLinkInNewTabItem, tabsBackUnwindsArticleStackItem], selectType: .multi)])

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
        
        tabsPreserveRabbitHoleItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.tabsPreserveRabbitHole = isSelected
        }.store(in: &subscribers)
        
        tabsDeepLinkInNewTabItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.tabsDeepLinkInNewTab = isSelected
        }.store(in: &subscribers)
        
        tabsBackUnwindsArticleStackItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.tabsBackUnwindsArticleStack = isSelected
        }.store(in: &subscribers)
    }
}
