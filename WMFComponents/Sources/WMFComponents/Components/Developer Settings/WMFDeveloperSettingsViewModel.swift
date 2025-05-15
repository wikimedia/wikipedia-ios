import Foundation
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let sendAnalyticsToWMFLabs: String
    let enableArticleTab: String
    let enableYearinReview: String
    let bypassDonation: String
    let forceEmailAuth: String
    let setActivityTabGroupA: String
    let setActivityTabGroupB: String
    let setActivityTabGroupC: String
    let done: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, enableArticleTab: String, enableYearinReview: String, bypassDonation: String, forceEmailAuth: String, setActivityTabGroupA: String, setActivityTabGroupB: String, setActivityTabGroupC: String, done: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.enableYearinReview = enableYearinReview
        self.enableArticleTab = enableArticleTab
        self.bypassDonation = bypassDonation
        self.forceEmailAuth = forceEmailAuth
        self.setActivityTabGroupA = setActivityTabGroupA
        self.setActivityTabGroupB = setActivityTabGroupB
        self.setActivityTabGroupC = setActivityTabGroupC
        self.done = done
    }
}

@objc public class WMFDeveloperSettingsViewModel: NSObject {

    let localizedStrings: WMFDeveloperSettingsLocalizedStrings
    let formViewModel: WMFFormViewModel
    private var subscribers: Set<AnyCancellable> = []
    private var activityTabGroupCoordinator: ActivityTabGroupBindingCoordinator?

    @objc public init(localizedStrings: WMFDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings

        // Form Items
        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)
        let bypassDonationItem = WMFFormItemSelectViewModel(title: localizedStrings.bypassDonation, isSelected: WMFDeveloperSettingsDataController.shared.bypassDonation)
        let forceEmailAuth = WMFFormItemSelectViewModel(title: localizedStrings.forceEmailAuth, isSelected: WMFDeveloperSettingsDataController.shared.forceEmailAuth)
        
        let enableArticleTabs = WMFFormItemSelectViewModel(title: "Enable article tabs", isSelected: WMFDeveloperSettingsDataController.shared.enableArticleTabs)
        
        let forceMaxArticleTabsTo5 = WMFFormItemSelectViewModel(title: "Force Max Article Tabs to 5", isSelected: WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5)

        let setActivityTabGroupA = WMFFormItemSelectViewModel(title: localizedStrings.setActivityTabGroupA, isSelected: WMFDeveloperSettingsDataController.shared.setActivityTabGroupA)
        let setActivityTabGroupB = WMFFormItemSelectViewModel(title: localizedStrings.setActivityTabGroupB, isSelected: WMFDeveloperSettingsDataController.shared.setActivityTabGroupB)
        let setActivityTabGroupC = WMFFormItemSelectViewModel(title: localizedStrings.setActivityTabGroupC, isSelected: WMFDeveloperSettingsDataController.shared.setActivityTabGroupC)

        // Form ViewModel
        formViewModel = WMFFormViewModel(sections: [
            WMFFormSectionSelectViewModel(items: [
                doNotPostImageRecommendationsEditItem,
                sendAnalyticsToWMFLabsItem,
                bypassDonationItem,
                forceEmailAuth,
                setActivityTabGroupA,
                setActivityTabGroupB,
                setActivityTabGroupC,
                enableArticleTabs,
                forceMaxArticleTabsTo5
            ], selectType: .multi)
        ])

        // Individual Toggle Bindings
        doNotPostImageRecommendationsEditItem.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit = isSelected }
            .store(in: &subscribers)

        sendAnalyticsToWMFLabsItem.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs = isSelected }
            .store(in: &subscribers)

        bypassDonationItem.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.bypassDonation = isSelected }
            .store(in: &subscribers)

        forceEmailAuth.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceEmailAuth = isSelected }
            .store(in: &subscribers)
        
        enableArticleTabs.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableArticleTabs = isSelected }
            .store(in: &subscribers)
        
        forceMaxArticleTabsTo5.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5 = isSelected }
            .store(in: &subscribers)

        activityTabGroupCoordinator = ActivityTabGroupBindingCoordinator(
            groupA: setActivityTabGroupA,
            groupB: setActivityTabGroupB,
            groupC: setActivityTabGroupC
        )
    }
}

private final class ActivityTabGroupBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(groupA: WMFFormItemSelectViewModel, groupB: WMFFormItemSelectViewModel, groupC: WMFFormItemSelectViewModel) {
        groupA.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.setActivityTabGroupA = isSelected
            if isSelected {
                groupB.isSelected = false
                groupC.isSelected = false
            }
        }.store(in: &subscribers)

        groupB.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.setActivityTabGroupB = isSelected
            if isSelected {
                groupA.isSelected = false
                groupC.isSelected = false
            }
        }.store(in: &subscribers)

        groupC.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.setActivityTabGroupC = isSelected
            if isSelected {
                groupA.isSelected = false
                groupB.isSelected = false
            }
        }.store(in: &subscribers)
    }
}
