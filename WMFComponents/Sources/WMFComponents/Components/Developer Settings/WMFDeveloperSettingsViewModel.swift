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
    let done: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, enableMoreDynamicTabsV2GroupB: String, enableMoreDynamicTabsV2GroupC: String, enableYearinReview: String, bypassDonation: String, forceEmailAuth: String, done: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.enableMoreDynamicTabsV2GroupB = enableMoreDynamicTabsV2GroupB
        self.enableMoreDynamicTabsV2GroupC = enableMoreDynamicTabsV2GroupC
        self.enableYearinReview = enableYearinReview
        self.bypassDonation = bypassDonation
        self.forceEmailAuth = forceEmailAuth
        self.done = done
    }
}

@objc public class WMFDeveloperSettingsViewModel: NSObject {

    let localizedStrings: WMFDeveloperSettingsLocalizedStrings
    let formViewModel: WMFFormViewModel
    private var subscribers: Set<AnyCancellable> = []
    private var moreDynamicTabsV2GroupCoordinator: MoreDynamicTabsV2GroupBindingCoordinator?
    private var yirLoginExperimentGroupCoordinator: YirLoginExperimentBindingCoordinator?
    private var activityTabGroupCoordinator: ActivityTabBindingCoordinator?

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

        let showYiRV3 = WMFFormItemSelectViewModel(title: "Show Year in Review Version 3", isSelected: WMFDeveloperSettingsDataController.shared.showYiRV3)

        let enableYiRVLoginExperimentControl = WMFFormItemSelectViewModel(title: "Force Year in Review Login Experiment Control", isSelected: WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControl)
        
        let enableYiRVLoginExperimentB = WMFFormItemSelectViewModel(title: "Force Year in Review Login Experiment B", isSelected: WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentB)

        let showActivityTab = WMFFormItemSelectViewModel(title: "Show Activity Tab", isSelected: WMFDeveloperSettingsDataController.shared.showActivityTab)

        let activityTabForceControl =  WMFFormItemSelectViewModel(title: "Activity Tab Control (history)", isSelected: WMFDeveloperSettingsDataController.shared.forceActivityTabControl)

        let activityTabForceExperiment =  WMFFormItemSelectViewModel(title: "Activity Tab Experiment", isSelected: WMFDeveloperSettingsDataController.shared.forceActivityTabExperiment)

        // Form ViewModel
        formViewModel = WMFFormViewModel(sections: [
            WMFFormSectionSelectViewModel(items: [
                doNotPostImageRecommendationsEditItem,
                sendAnalyticsToWMFLabsItem,
                bypassDonationItem,
                forceEmailAuth,
                forceMaxArticleTabsTo5,
                enableMoreDynamicTabsV2GroupB,
                enableMoreDynamicTabsV2GroupC,
                showYiRV3,
                enableYiRVLoginExperimentControl,
                enableYiRVLoginExperimentB,
                showActivityTab,
                activityTabForceControl,
                activityTabForceExperiment
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
        
        showActivityTab.$isSelected
            .sink { isSelected in
                WMFDeveloperSettingsDataController.shared.showActivityTab = isSelected

            }
            .store(in: &subscribers)

        showYiRV3.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.showYiRV3 = isSelected }
            .store(in: &subscribers)
        
        enableYiRVLoginExperimentControl.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControl = isSelected }
            .store(in: &subscribers)
        
        enableYiRVLoginExperimentB.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentB = isSelected }
            .store(in: &subscribers)
        
        moreDynamicTabsV2GroupCoordinator = MoreDynamicTabsV2GroupBindingCoordinator(groupB: enableMoreDynamicTabsV2GroupB, groupC: enableMoreDynamicTabsV2GroupC)

        yirLoginExperimentGroupCoordinator = YirLoginExperimentBindingCoordinator(
            control: enableYiRVLoginExperimentControl,
            b: enableYiRVLoginExperimentB
        )

        activityTabGroupCoordinator = ActivityTabBindingCoordinator(
            main: showActivityTab,
            control: activityTabForceControl,
            experiment: activityTabForceExperiment
        )
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

private final class YirLoginExperimentBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(control: WMFFormItemSelectViewModel, b: WMFFormItemSelectViewModel) {
        control.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControl = isSelected
            if isSelected {
                b.isSelected = false
            }
        }.store(in: &subscribers)

        b.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentB = isSelected
            if isSelected {
                control.isSelected = false
            }
        }.store(in: &subscribers)

    }
}

private final class ActivityTabBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(main: WMFFormItemSelectViewModel, control: WMFFormItemSelectViewModel, experiment: WMFFormItemSelectViewModel) {
        main.$isSelected
            .sink { isSelected in
                if !isSelected {
                    control.isSelected = false
                    experiment.isSelected = false
                }

            }
            .store(in: &subscribers)

        control.$isSelected
            .sink { isSelected in
                WMFDeveloperSettingsDataController.shared.forceActivityTabControl = isSelected

                guard isSelected else {
                    return
                }
                if !main.isSelected {
                    main.isSelected = true
                }
                if experiment.isSelected {
                    experiment.isSelected = false
                }

            }
            .store(in: &subscribers)

        experiment.$isSelected
            .sink { isSelected in
                WMFDeveloperSettingsDataController.shared.forceActivityTabExperiment = isSelected

                if isSelected {
                    if !main.isSelected {
                        main.isSelected = true
                    }
                    if control.isSelected {
                        control.isSelected = false
                    }
                }
                NotificationCenter.default.post(
                    name: WMFNSNotification.activityTab,
                    object: nil,
                    userInfo: ["isOn": isSelected]
                )
            }
            .store(in: &subscribers)
    }
}
