import Foundation
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let sendAnalyticsToWMFLabs: String
    let enableYearinReview: String
    let bypassDonation: String
    let done: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, enableYearinReview: String, bypassDonation: String, close: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
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
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)

        let bypassDonationItem = WMFFormItemSelectViewModel(title: localizedStrings.bypassDonation, isSelected: WMFDeveloperSettingsDataController.shared.bypassDonation)
        
        let tabsDoNotPreserveBackHistoryItem = WMFFormItemSelectViewModel(title: "Tabs - Do not preserve back history", isSelected: WMFDeveloperSettingsDataController.shared.tabsDoNotPreserveBackHistory)
        
        let tabsDeepLinkInCurrentTabItem = WMFFormItemSelectViewModel(title: "Tabs - Deep Link In current tab", isSelected: WMFDeveloperSettingsDataController.shared.tabsDeepLinkInCurrentTab)

        formViewModel = WMFFormViewModel(sections: [WMFFormSectionSelectViewModel(items: [doNotPostImageRecommendationsEditItem, sendAnalyticsToWMFLabsItem, bypassDonationItem, tabsDoNotPreserveBackHistoryItem, tabsDeepLinkInCurrentTabItem], selectType: .multi)])

        doNotPostImageRecommendationsEditItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit = isSelected
        }.store(in: &subscribers)
        
        sendAnalyticsToWMFLabsItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs = isSelected
        }.store(in: &subscribers)

        bypassDonationItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.bypassDonation = isSelected
        }.store(in: &subscribers)
        
        tabsDoNotPreserveBackHistoryItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.tabsDoNotPreserveBackHistory = isSelected
        }.store(in: &subscribers)
        
        tabsDeepLinkInCurrentTabItem.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.tabsDeepLinkInCurrentTab = isSelected
        }.store(in: &subscribers)
    }
}
