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

    @objc public init(developerSettings: String, doNotPostImageRecommendations: String, sendAnalyticsToWMFLabs: String, enableMoreDynamicTabsV2GroupC: String, enableYearinReview: String, bypassDonation: String, forceEmailAuth: String, done: String) {
        self.developerSettings = developerSettings
        self.doNotPostImageRecommendations = doNotPostImageRecommendations
        self.sendAnalyticsToWMFLabs = sendAnalyticsToWMFLabs
        self.enableMoreDynamicTabsV2GroupC = enableMoreDynamicTabsV2GroupC
        self.enableYearinReview = enableYearinReview
        self.bypassDonation = bypassDonation
        self.forceEmailAuth = forceEmailAuth
    }
}

@objc public class WMFDeveloperSettingsViewModel: NSObject, ObservableObject {

    let localizedStrings: WMFDeveloperSettingsLocalizedStrings
    let formViewModel: WMFFormViewModel
    
    private var subscribers: Set<AnyCancellable> = []
    private var yirLoginExperimentGroupCoordinator: YirLoginExperimentBindingCoordinator?
    
    @Published public var enableDeveloperMode: Bool = WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode {
        didSet {
            WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode = enableDeveloperMode
        }
    }
    
    @Published public var readingChallengeOverrideCurrentDate: Bool = WMFDeveloperSettingsDataController.shared.devReadingChallengeOverrideCurrentDate ?? false {
        didSet {
            WMFDeveloperSettingsDataController.shared.setDevReadingChallengeOverrideCurrentDate(readingChallengeOverrideCurrentDate)

            if readingChallengeOverrideCurrentDate == true {
                WMFDeveloperSettingsDataController.shared.setDevReadingChallengeCurrentDate(readingChallengeCurrentDate)
                if readingChallengeState != nil {
                    readingChallengeState = nil
                }
            } else {
                WMFDeveloperSettingsDataController.shared.setDevReadingChallengeCurrentDate(nil)
            }
            
            WMFDeveloperSettingsDataController.shared.reloadReadingChallengeWidget()
        }
    }
    
    @Published public var readingChallengeCurrentDate: Date = WMFDeveloperSettingsDataController.shared.devReadingChallengeCurrentDate ?? Date() {
        didSet {
            if readingChallengeOverrideCurrentDate == true {
                WMFDeveloperSettingsDataController.shared.setDevReadingChallengeCurrentDate(readingChallengeCurrentDate)
            } else {
                WMFDeveloperSettingsDataController.shared.setDevReadingChallengeCurrentDate(nil)
            }
            
            WMFDeveloperSettingsDataController.shared.reloadReadingChallengeWidget()
        }
    }
    
    @Published public var readingChallengeStreakCount: Int = {
        switch WMFDeveloperSettingsDataController.shared.devReadingChallengeState {
        case .streakOngoingRead(let streak), .streakOngoingNotYetRead(let streak), .challengeConcludedIncomplete(let streak):
            return streak
        default:
            return 7
        }
    }() {
        didSet {
            let clamped = max(1, min(24, readingChallengeStreakCount))
            if clamped != readingChallengeStreakCount {
                readingChallengeStreakCount = clamped
                return
            }
            switch readingChallengeState {
            case .streakOngoingRead:
                readingChallengeState = .streakOngoingRead(streak: clamped)
            case .streakOngoingNotYetRead:
                readingChallengeState = .streakOngoingNotYetRead(streak: clamped)
            case .challengeConcludedIncomplete:
                readingChallengeState = .challengeConcludedIncomplete(streak: clamped)
            default:
                break
            }
            
            WMFDeveloperSettingsDataController.shared.reloadReadingChallengeWidget()
        }
    }

    @Published public var readingChallengeState: ReadingChallengeState? = WMFDeveloperSettingsDataController.shared.devReadingChallengeState {
        didSet {
            WMFDeveloperSettingsDataController.shared.devReadingChallengeState = readingChallengeState
            if readingChallengeState == nil {
                readingChallengeStreakCount = 7
            } else if readingChallengeOverrideCurrentDate {
                readingChallengeOverrideCurrentDate = false
            }
            
            WMFDeveloperSettingsDataController.shared.reloadReadingChallengeWidget()
        }
    }

    @objc public init(localizedStrings: WMFDeveloperSettingsLocalizedStrings) {
        self.localizedStrings = localizedStrings

        // Form Items
        let doNotPostImageRecommendationsEditItem = WMFFormItemSelectViewModel(title: localizedStrings.doNotPostImageRecommendations, isSelected: WMFDeveloperSettingsDataController.shared.doNotPostImageRecommendationsEdit)
        let sendAnalyticsToWMFLabsItem = WMFFormItemSelectViewModel(title: localizedStrings.sendAnalyticsToWMFLabs, isSelected: WMFDeveloperSettingsDataController.shared.sendAnalyticsToWMFLabs)
        let bypassDonationItem = WMFFormItemSelectViewModel(title: localizedStrings.bypassDonation, isSelected: WMFDeveloperSettingsDataController.shared.bypassDonation)
        let forceEmailAuth = WMFFormItemSelectViewModel(title: localizedStrings.forceEmailAuth, isSelected: WMFDeveloperSettingsDataController.shared.forceEmailAuth)
        let forceMaxArticleTabsTo5 = WMFFormItemSelectViewModel(title: "Force Max Article Tabs to 5", isSelected: WMFDeveloperSettingsDataController.shared.forceMaxArticleTabsTo5)
        let enableMoreDynamicTabsV2GroupC = WMFFormItemSelectViewModel(title: localizedStrings.enableMoreDynamicTabsV2GroupC, isSelected: WMFDeveloperSettingsDataController.shared.enableMoreDynamicTabsV2GroupC)
        let showYiRV3 = WMFFormItemSelectViewModel(title: "Show Year in Review Version 3", isSelected: WMFDeveloperSettingsDataController.shared.showYiRV3)
        let enableYiRVLoginExperimentControl = WMFFormItemSelectViewModel(title: "Force Year in Review Login Experiment Control", isSelected: WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControl)
        let enableYiRVLoginExperimentB = WMFFormItemSelectViewModel(title: "Force Year in Review Login Experiment B", isSelected: WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentB)
        let forceHcaptchaChallenge = WMFFormItemSelectViewModel(title: "Force hCaptcha Challenge", isSelected: WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge)

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
                forceHcaptchaChallenge
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

        showYiRV3.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.showYiRV3 = isSelected }
            .store(in: &subscribers)
        
        enableYiRVLoginExperimentControl.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControl = isSelected }
            .store(in: &subscribers)
        
        enableYiRVLoginExperimentB.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentB = isSelected }
            .store(in: &subscribers)
        
        forceHcaptchaChallenge.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge = isSelected }
            .store(in: &subscribers)

        yirLoginExperimentGroupCoordinator = YirLoginExperimentBindingCoordinator(
            control: enableYiRVLoginExperimentControl,
            b: enableYiRVLoginExperimentB
        )
    }

    public func clearAllReadingChallengePersistence() {
        readingChallengeOverrideCurrentDate = false
        readingChallengeCurrentDate = Date()
        readingChallengeState = nil
        readingChallengeStreakCount = 7
        WMFDeveloperSettingsDataController.shared.devClearAllReadingChallengePersistence()
    }
}

private final class YirLoginExperimentBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(control: WMFFormItemSelectViewModel, b: WMFFormItemSelectViewModel) {
        control.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentControl = isSelected
            if isSelected { b.isSelected = false }
        }.store(in: &subscribers)
        b.$isSelected.sink { isSelected in
            WMFDeveloperSettingsDataController.shared.enableYiRLoginExperimentB = isSelected
            if isSelected { control.isSelected = false }
        }.store(in: &subscribers)
    }
}
