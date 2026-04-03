import Foundation
import WMFData

#if DEBUG

final class WMFMockDeveloperSettingsDataController: WMFDeveloperSettingsDataControlling {

    var enableYearInReview: Bool { return true }
    var enableActivityTabs: Bool { return true }
    var enableArticleTabs: Bool { return true }
    var forceMaxArticleTabsTo5: Bool { return false }
    var enableMoreDynamicTabsV2GroupB: Bool { return true }
    var enableMoreDynamicTabsV2GroupC: Bool { return false }
    var showYiRV3: Bool { return true }
    var enableYiRLoginExperimentControl: Bool { return false }
    var enableYiRLoginExperimentB: Bool { return false }
    var readingChallengeDatesRelativeToToday: Bool { return false }
    var devForceReadingChallengeEnabled: Bool { get { false } set {} }
    var devForceReadingChallengeStreakCount: Int { get { 7 } set {} }
    var devForceReadingChallengeCompletedFullStreak: Bool { get { false } set {} }
    var devForceReadingChallengeCompletedIncompleteStreak: Bool { get { false } set {} }
    var devForceReadingChallengeCompletedNoStreak: Bool { get { false } set {} }
    var devForceReadingChallengeNotLiveYet: Bool { get { false } set {} }
    var devForceReadingChallengeNotEnrolled: Bool { get { false } set {} }
    var devForceReadingChallengeEnrolledNotStarted: Bool { get { false } set {} }
    var devForceReadingChallengeStreakOngoingRead: Bool { get { false } set {} }
    var devForceReadingChallengeStreakOngoingNotYetRead: Bool { get { false } set {} }
    var forcedReadingChallengeState: ReadingChallengeState? { return nil }

    private let featureConfig: WMFData.WMFFeatureConfigResponse

    public init(featureConfig: WMFData.WMFFeatureConfigResponse) {
        self.featureConfig = featureConfig
    }

    func loadFeatureConfig() -> WMFData.WMFFeatureConfigResponse? {
        return self.featureConfig
    }
}

#endif
