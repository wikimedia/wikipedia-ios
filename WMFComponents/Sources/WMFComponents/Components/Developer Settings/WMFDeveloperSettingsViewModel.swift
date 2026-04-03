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
    @Published public var streakCount: Int = WMFDeveloperSettingsDataController.shared.devForceReadingChallengeStreakCount
    private var subscribers: Set<AnyCancellable> = []
    private var yirLoginExperimentGroupCoordinator: YirLoginExperimentBindingCoordinator?
    private var readingChallengeForceStateCoordinator: ReadingChallengeForceStateBindingCoordinator?

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
        let readingChallengeDatesRelativeToToday = WMFFormItemSelectViewModel(title: "Reading Challenge: Use Relative Dates", isSelected: WMFDeveloperSettingsDataController.shared.readingChallengeDatesRelativeToToday)
        let rcForceEnabled = WMFFormItemSelectViewModel(title: "Force Reading Challenge State: ON", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeEnabled)

        // Reading Challenge force state (exclusive)
        let rcNotLiveYet = WMFFormItemSelectViewModel(title: "Force: Not live yet", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeNotLiveYet)
        let rcNotEnrolled = WMFFormItemSelectViewModel(title: "Force: Not enrolled", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeNotEnrolled)
        let rcEnrolledNotStarted = WMFFormItemSelectViewModel(title: "Force: Enrolled, not started", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeEnrolledNotStarted)
        let rcStreakRead = WMFFormItemSelectViewModel(title: "Force: Streak ongoing - read today", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeStreakOngoingRead)
        let rcStreakNotYetRead = WMFFormItemSelectViewModel(title: "Force: Streak ongoing - not yet read", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeStreakOngoingNotYetRead)
        let rcCompletedFull = WMFFormItemSelectViewModel(title: "Force: Completed - full streak", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeCompletedFullStreak)
        let rcCompletedIncomplete = WMFFormItemSelectViewModel(title: "Force: Completed - incomplete streak", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeCompletedIncompleteStreak)
        let rcCompletedNoStreak = WMFFormItemSelectViewModel(title: "Force: Completed - no streak", isSelected: WMFDeveloperSettingsDataController.shared.devForceReadingChallengeCompletedNoStreak)

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
                forceHcaptchaChallenge,
                readingChallengeDatesRelativeToToday,
                rcForceEnabled
            ], selectType: .multi),
            WMFFormSectionSelectViewModel(header: "Force Reading Challenge State", items: [
                rcNotLiveYet,
                rcNotEnrolled,
                rcEnrolledNotStarted,
                rcStreakRead,
                rcStreakNotYetRead,
                rcCompletedFull,
                rcCompletedIncomplete,
                rcCompletedNoStreak
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
        
        readingChallengeDatesRelativeToToday.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.readingChallengeDatesRelativeToToday = isSelected }
            .store(in: &subscribers)

        rcForceEnabled.$isSelected
            .sink { isSelected in WMFDeveloperSettingsDataController.shared.devForceReadingChallengeEnabled = isSelected }
            .store(in: &subscribers)

        yirLoginExperimentGroupCoordinator = YirLoginExperimentBindingCoordinator(
            control: enableYiRVLoginExperimentControl,
            b: enableYiRVLoginExperimentB
        )

        readingChallengeForceStateCoordinator = ReadingChallengeForceStateBindingCoordinator(
            notLiveYet: rcNotLiveYet,
            notEnrolled: rcNotEnrolled,
            enrolledNotStarted: rcEnrolledNotStarted,
            streakRead: rcStreakRead,
            streakNotYetRead: rcStreakNotYetRead,
            completedFull: rcCompletedFull,
            completedIncomplete: rcCompletedIncomplete,
            completedNoStreak: rcCompletedNoStreak
        )
    }

    public func resetReadingChallengeState() {
        WMFDeveloperSettingsDataController.shared.resetReadingChallengeState()
    }

    public func setStreakCount(_ count: Int) {
        let clamped = min(max(count, 1), 25)
        streakCount = clamped
        WMFDeveloperSettingsDataController.shared.devForceReadingChallengeStreakCount = clamped
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

private final class ReadingChallengeForceStateBindingCoordinator {
    private var subscribers: Set<AnyCancellable> = []

    init(
        notLiveYet: WMFFormItemSelectViewModel,
        notEnrolled: WMFFormItemSelectViewModel,
        enrolledNotStarted: WMFFormItemSelectViewModel,
        streakRead: WMFFormItemSelectViewModel,
        streakNotYetRead: WMFFormItemSelectViewModel,
        completedFull: WMFFormItemSelectViewModel,
        completedIncomplete: WMFFormItemSelectViewModel,
        completedNoStreak: WMFFormItemSelectViewModel
    ) {
        let all = [notLiveYet, notEnrolled, enrolledNotStarted, streakRead, streakNotYetRead, completedFull, completedIncomplete, completedNoStreak]

        func bind(_ item: WMFFormItemSelectViewModel, setter: @escaping (Bool) -> Void) {
            item.$isSelected.sink { isSelected in
                setter(isSelected)
                if isSelected { all.forEach { if $0 !== item { $0.isSelected = false } } }
            }.store(in: &subscribers)
        }

        bind(notLiveYet) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeNotLiveYet = $0 }
        bind(notEnrolled) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeNotEnrolled = $0 }
        bind(enrolledNotStarted) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeEnrolledNotStarted = $0 }
        bind(streakRead) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeStreakOngoingRead = $0 }
        bind(streakNotYetRead) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeStreakOngoingNotYetRead = $0 }
        bind(completedFull) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeCompletedFullStreak = $0 }
        bind(completedIncomplete) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeCompletedIncompleteStreak = $0 }
        bind(completedNoStreak) { WMFDeveloperSettingsDataController.shared.devForceReadingChallengeCompletedNoStreak = $0 }
    }
}
