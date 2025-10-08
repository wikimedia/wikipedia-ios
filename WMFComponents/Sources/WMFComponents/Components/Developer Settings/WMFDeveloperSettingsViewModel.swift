import Foundation
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let sendAnalyticsToWMFLabs: String
    let enableMoreDynamicTabsV2GroupB: String
    let enableMoreDynamicTabsV2GroupC: String
    let enableYearinReview: String
    let bypassDonation: String
    let forceEmailAuth: String
    let setActivityTabGroupA: String
    let setActivityTabGroupB: String
    let setActivityTabGroupC: String
    let done: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, enableMoreDynamicTabsV2GroupB: String, enableMoreDynamicTabsV2GroupC: String, enableYearinReview: String, bypassDonation: String, forceEmailAuth: String, setActivityTabGroupA: String, setActivityTabGroupB: String, setActivityTabGroupC: String, done: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.enableMoreDynamicTabsV2GroupB = enableMoreDynamicTabsV2GroupB
        self.enableMoreDynamicTabsV2GroupC = enableMoreDynamicTabsV2GroupC
        self.enableYearinReview = enableYearinReview
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
    private var moreDynamicTabsV2GroupCoordinator: MoreDynamicTabsV2GroupBindingCoordinator?
    private var yirGroupCoordinator: YearInReviewGroupBindingCoordinator?

    @objc public init(localizedStrings: WMFDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings

        // Form Items
        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)
        let bypassDonationItem = WMFFormItemSelectViewModel(title: localizedStrings.bypassDonation, isSelected: WMFDeveloperSettingsDataController.shared.bypassDonation)
        let forceEmailAuth = WMFFormItemSelectViewModel(title: localizedStrings.forceEmailAuth, isSelected: WMFDeveloperSettingsDataController.shared.forceEmailAuth)
        
        let forceMaxArticleTabsTo5 = WMFFormItemSelectViewModel(title: "Force Max Article Tabs to 5", isSelected: WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5)
        
        
        // V2 tabs
        let enableMoreDynamicTabsV2GroupB = WMFFormItemSelectViewModel(title: localizedStrings.enableMoreDynamicTabsV2GroupB, isSelected: WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupB)
        let enableMoreDynamicTabsV2GroupC = WMFFormItemSelectViewModel(title: localizedStrings.enableMoreDynamicTabsV2GroupC, isSelected: WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupC)

        let setActivityTabGroupA = WMFFormItemSelectViewModel(title: localizedStrings.setActivityTabGroupA, isSelected: WMFDeveloperSettingsDataController.shared.setActivityTabGroupA)
        let setActivityTabGroupB = WMFFormItemSelectViewModel(title: localizedStrings.setActivityTabGroupB, isSelected: WMFDeveloperSettingsDataController.shared.setActivityTabGroupB)
        let setActivityTabGroupC = WMFFormItemSelectViewModel(title: localizedStrings.setActivityTabGroupC, isSelected: WMFDeveloperSettingsDataController.shared.setActivityTabGroupC)
        
        
        let showYiRV2 = WMFFormItemSelectViewModel(title: "Show Year in Review Version 2", isSelected: WMFDeveloperSettingsDataController.shared.showYiRV2)
        
        let showYiRV3 = WMFFormItemSelectViewModel(title: "Show Year in Review Version 3", isSelected: WMFDeveloperSettingsDataController.shared.showYiRV3)

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
                forceMaxArticleTabsTo5,
                enableMoreDynamicTabsV2GroupB,
                enableMoreDynamicTabsV2GroupC,
                showYiRV2,
                showYiRV3
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
        
        forceMaxArticleTabsTo5.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5 = isSelected }
            .store(in: &subscribers)
        
        enableMoreDynamicTabsV2GroupB.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupB = isSelected }
            .store(in: &subscribers)
        
        moreDynamicTabsV2GroupCoordinator = MoreDynamicTabsV2GroupBindingCoordinator(groupB: enableMoreDynamicTabsV2GroupB, groupC: enableMoreDynamicTabsV2GroupC)

        activityTabGroupCoordinator = ActivityTabGroupBindingCoordinator(
            groupA: setActivityTabGroupA,
            groupB: setActivityTabGroupB,
            groupC: setActivityTabGroupC
        )
        
        yirGroupCoordinator = YearInReviewGroupBindingCoordinator(showYiRV2: showYiRV2, showYiRV3: showYiRV3)
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

private final class MoreDynamicTabsV2GroupBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(groupB: WMFFormItemSelectViewModel, groupC: WMFFormItemSelectViewModel) {
        groupB.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupB = isSelected
            if isSelected {
                groupC.isSelected = false
            }
        }.store(in: &subscribers)

        groupC.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupC = isSelected
            if isSelected {
                groupB.isSelected = false
            }
        }.store(in: &subscribers)

    }
}


private final class YearInReviewGroupBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(showYiRV2: WMFFormItemSelectViewModel, showYiRV3: WMFFormItemSelectViewModel) {
        
        showYiRV2.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.showYiRV2 = isSelected
            if isSelected {
                showYiRV3.isSelected = false
            }
        }.store(in: &subscribers)

        showYiRV3.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.showYiRV3 = isSelected
            if isSelected {
                showYiRV2.isSelected = false
            }
        }.store(in: &subscribers)
    }
}
