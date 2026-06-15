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
    
    @Published public var enableDeveloperMode: Bool = WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode {
        didSet {
            WMFDeveloperSettingsDataController.shared.developerSettingsEnableDeveloperMode = enableDeveloperMode
        }
    }

    @Published public var showGamesV2: Bool = WMFDeveloperSettingsDataController.shared.showGamesV2 {
        didSet {
            WMFDeveloperSettingsDataController.shared.showGamesV2 = showGamesV2
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
        let showYiR2025 = WMFFormItemSelectViewModel(title: "Show Year in Review 2025", isSelected: WMFDeveloperSettingsDataController.shared.showYiR2025)
        let forceHcaptchaChallenge = WMFFormItemSelectViewModel(title: "Force hCaptcha Challenge", isSelected: WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge)
        let allowGestureZoomArticleWebview = WMFFormItemSelectViewModel(title: "Allow pinch to zoom when reading articles", isSelected: WMFDeveloperSettingsDataController.shared.allowGestureZoomArticleWebview)
        let enableHomeTab = WMFFormItemSelectViewModel(title: "Enable Home Tab", isSelected: WMFDeveloperSettingsDataController.shared.enableHomeTab)

        formViewModel = WMFFormViewModel(sections: [
            WMFFormSectionSelectViewModel(items: [
                enableHomeTab,
                doNotPostImageRecommendationsEditItem,
                sendAnalyticsToWMFLabsItem,
                bypassDonationItem,
                forceEmailAuth,
                forceMaxArticleTabsTo5,
                enableMoreDynamicTabsV2GroupC,
                showYiR2025,
                forceHcaptchaChallenge,
                allowGestureZoomArticleWebview
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

        showYiR2025.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.showYiR2025 = isSelected }
            .store(in: &subscribers)

        forceHcaptchaChallenge.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.forceHCaptchaChallenge = isSelected }
            .store(in: &subscribers)

        allowGestureZoomArticleWebview.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.allowGestureZoomArticleWebview = isSelected }
            .store(in: &subscribers)

        enableHomeTab.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.enableHomeTab = isSelected }
            .store(in: &subscribers)
    }

    public func clearAllReadingChallengePersistence() {
        readingChallengeOverrideCurrentDate = false
        readingChallengeCurrentDate = Date()
        readingChallengeState = nil
        readingChallengeStreakCount = 7
        WMFDeveloperSettingsDataController.shared.devClearAllReadingChallengePersistence()
    }

    public func clearGamesPersistence() {
        Task {
            try? await WMFDeveloperSettingsDataController.shared.clearGamesPersistence()
        }
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
