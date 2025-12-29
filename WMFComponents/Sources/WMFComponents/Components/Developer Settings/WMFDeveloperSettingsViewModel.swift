import Foundation
import Combine
import WMFData

@objc public class WMFDeveloperSettingsLocalizedStrings: NSObject {
    let developerSettings: String
    let doNotPostImageRecommendations: String
    let sendAnalyticsToWMFLabs: String
    let enableMoreDynamicTabsV2GroupC: String
    let enableYearinReview: String
    let bypassDonation: String
    let forceEmailAuth: String
    let done: String

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, enableMoreDynamicTabsV2GroupC: String, enableYearinReview: String, bypassDonation: String, forceEmailAuth: String, done: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
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
    private var yirLoginExperimentGroupCoordinator: YirLoginExperimentBindingCoordinator?
    private var activityTabGroupCoordinator: ActivityTabBindingCoordinator?

    @objc public init(localizedStrings: WMFDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings

        // Form Items
        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEditSyncBridge)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabsSyncBridge)
        let bypassDonationItem = WMFFormItemSelectViewModel(title: localizedStrings.bypassDonation, isSelected: WMFDeveloperSettingsDataController.shared.bypassDonationSyncBridge)
        let forceEmailAuth = WMFFormItemSelectViewModel(title: localizedStrings.forceEmailAuth, isSelected: WMFDeveloperSettingsDataController.shared.forceEmailAuthSyncBridge)
        
        let forceMaxArticleTabsTo5 = WMFFormItemSelectViewModel(title: "Force Max Article Tabs to 5", isSelected: WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5SyncBridge)
        
        // V2 tabs
        let enableMoreDynamicTabsV2GroupC = WMFFormItemSelectViewModel(title: localizedStrings.enableMoreDynamicTabsV2GroupC, isSelected: WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupCSyncBridge)

        let showYiRV3 = WMFFormItemSelectViewModel(title: "Show Year in Review Version 3", isSelected: WMFDeveloperSettingsDataController.shared.showYiRV3SyncBridge)

        let enableYiRVLoginExperimentControl = WMFFormItemSelectViewModel(title: "Force Year in Review Login Experiment Control", isSelected: WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControlSyncBridge)
        
        let enableYiRVLoginExperimentB = WMFFormItemSelectViewModel(title: "Force Year in Review Login Experiment B", isSelected: WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentBSyncBridge)

        let showActivityTab = WMFFormItemSelectViewModel(title: "Show Activity Tab", isSelected: WMFDeveloperSettingsDataController.shared.showActivityTabSyncBridge)

        let activityTabForceControl =  WMFFormItemSelectViewModel(title: "Activity Tab Control (history)", isSelected: WMFDeveloperSettingsDataController.shared.forceActivityTabControlSyncBridge)

        let activityTabForceExperiment =  WMFFormItemSelectViewModel(title: "Activity Tab Experiment", isSelected: WMFDeveloperSettingsDataController.shared.forceActivityTabExperimentSyncBridge)

        // Form ViewModel
        formViewModel = WMFFormViewModel(sections: [
            WMFFormSectionSelectViewModel(items: [
                doNotPostImageRecommendationsEditItem,
                sendAnalyticsToWMFLabsItem,
                bypassDonationItem,
                forceEmailAuth,
                forceMaxArticleTabsTo5,
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
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setDoNotPostImageRecommendationsEdit(isSelected)
                }
            }
            .store(in: &subscribers)

        sendAnalyticsToWMFLabsItem.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setSendAnalyticsToWMFLabs(isSelected)
                }
            }
            .store(in: &subscribers)

        bypassDonationItem.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setBypassDonation(isSelected)
                }
            }
            .store(in: &subscribers)

        forceEmailAuth.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setForceEmailAuth(isSelected)
                }
            }
            .store(in: &subscribers)
        
        forceMaxArticleTabsTo5.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setForceMaxArticleTabsTo5(isSelected)
                }
            }
            .store(in: &subscribers)
        
        showActivityTab.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setShowActivityTab(isSelected)
                }
            }
            .store(in: &subscribers)

        showYiRV3.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setShowYiRV3(isSelected)
                }
            }
            .store(in: &subscribers)
        
        enableYiRVLoginExperimentControl.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setEnableYiRLoginExperimentControl(isSelected)
                }
            }
            .store(in: &subscribers)
        
        enableYiRVLoginExperimentB.$isSelected
            .sink { isSelected in
                Task {
                    await WMFDeveloperSettingsDataController.shared.setEnableYiRLoginExperimentB(isSelected)
                }
            }
            .store(in: &subscribers)
        
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

private final class YirLoginExperimentBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(control: WMFFormItemSelectViewModel, b: WMFFormItemSelectViewModel) {
        control.$isSelected.sink { isSelected in
            Task {
                await WMFDeveloperSettingsDataController.shared.setEnableYiRLoginExperimentControl(isSelected)
            }
            if isSelected {
                b.isSelected = false
            }
        }.store(in: &subscribers)

        b.$isSelected.sink { isSelected in
            
            Task {
                await WMFDeveloperSettingsDataController.shared.setEnableYiRLoginExperimentB(isSelected)
            }
            
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
                
                Task {
                    await WMFDeveloperSettingsDataController.shared.setForceActivityTabControl(isSelected)
                }
                
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
                
                Task {
                    await WMFDeveloperSettingsDataController.shared.setForceActivityTabExperiment(isSelected)
                }

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
