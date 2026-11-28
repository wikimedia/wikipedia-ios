import Foundation
import XCTest

/// Provides access to the current UI-test launch configuration from XCTest helpers.
extension XCTestCase {
    var uiTestConfiguration: UITestConfiguration {
        UITestConfiguration()
    }

    /// Skips the test in the live-network E2E configuration, for tests that depend on fixture
    /// content or fixture-only state that live services do not reproduce.
    func skipInE2E(_ reason: String) throws {
        try XCTSkipIf(uiTestConfiguration.httpClientProfile == TestHTTPClientProfile.e2e.rawValue, reason)
    }
}

/// Captures the launch-time settings that make UI tests deterministic across theme, language, onboarding state, and network profile.
struct UITestConfiguration {
    var onboardingState: OnboardingState
    let httpClientProfile: String
    let resetsPreferredLanguages: Bool
    let suppressesActivityTabOnboarding: Bool
    let suppressesGamesAnnouncement: Bool
    let suppressesHomeOnboarding: Bool
    let centralAuthUsername: String?
    let themeName: String?
    let languageCode: String
    let readingListsSeed: UITestReadingListsSeed?
    let discoverState: DiscoverState
    let homePhase: HomePhase
    let homeFeedState: UITestHomeFeedState?
    let offlineRequests: [UITestOfflineRequest]

    var isRightToLeft: Bool {
        NSLocale.characterDirection(forLanguage: languageCode) == .rightToLeft
    }

    init(
        onboardingState: OnboardingState = .completed,
        resetsPreferredLanguages: Bool = true,
        suppressesActivityTabOnboarding: Bool = true,
        suppressesGamesAnnouncement: Bool = true,
        suppressesHomeOnboarding: Bool = true,
        readingListsSeed: UITestReadingListsSeed? = nil,
        centralAuthUsername: String? = nil,
        discoverState: DiscoverState = .off,
        homePhase: HomePhase = .phase1,
        homeFeedState: UITestHomeFeedState? = nil,
        offlineRequests: [UITestOfflineRequest] = []
    ) {
        self.onboardingState = onboardingState
        self.homePhase = homePhase
        self.homeFeedState = homeFeedState
        self.offlineRequests = offlineRequests
        self.readingListsSeed = readingListsSeed
        self.discoverState = discoverState
        self.httpClientProfile = ProcessInfo.processInfo.value(for: .httpClientProfile) ?? defaultHTTPClientProfile
        self.themeName = ProcessInfo.processInfo.value(for: .appThemeName)
        self.resetsPreferredLanguages = resetsPreferredLanguages
        self.suppressesActivityTabOnboarding = suppressesActivityTabOnboarding
        self.suppressesGamesAnnouncement = suppressesGamesAnnouncement
        self.suppressesHomeOnboarding = suppressesHomeOnboarding
        self.centralAuthUsername = centralAuthUsername
        self.languageCode = ProcessInfo.processInfo.value(for: .uiTestLanguageCode) ?? defaultLanguageCode
    }

    var launchArguments: [UITestLaunchArgumentValue] {
        var argumentValues: [UITestLaunchArgumentValue] = []

        if let themeName {
            argumentValues.append(UITestLaunchArgumentValue(.appThemeName, value: themeName))
        }

        if resetsPreferredLanguages {
            argumentValues.append(UITestLaunchArgumentValue(.resetPreferredLanguages, value: "YES"))
        }

        if suppressesActivityTabOnboarding {
            argumentValues.append(UITestLaunchArgumentValue(.suppressActivityTabOnboarding, value: "YES"))
        }

        if suppressesGamesAnnouncement {
            argumentValues.append(UITestLaunchArgumentValue(.suppressGamesAnnouncement, value: "YES"))
        }

        if suppressesHomeOnboarding {
            argumentValues.append(UITestLaunchArgumentValue(.suppressHomeOnboarding, value: "YES"))
        }

        argumentValues.append(UITestLaunchArgumentValue(.suppressYearInReviewAnnouncement, value: "YES"))

        // Always passed explicitly: the cookie persists across launches, so an empty value
        // clears the centralauth_User cookie a previous test seeded.
        argumentValues.append(UITestLaunchArgumentValue(.centralAuthUsername, value: centralAuthUsername ?? ""))

        argumentValues.append(UITestLaunchArgumentValue(.appleLanguages, value: "(\(languageCode))"))
        argumentValues.append(UITestLaunchArgumentValue(.httpClientProfile, value: httpClientProfile))
        argumentValues.append(UITestLaunchArgumentValue(.hideTipsForTesting, value: "YES"))
        argumentValues.append(UITestLaunchArgumentValue(.didShowOnboarding, value: onboardingState.launchArgumentValue))

        if let readingListsSeed {
            argumentValues.append(UITestLaunchArgumentValue(.readingListsSeed, value: readingListsSeed.launchArgumentValue))
        }

        if discoverState != .keep {
            argumentValues.append(UITestLaunchArgumentValue(.discoverState, value: discoverState.rawValue))
        }

        // Always passed explicitly: the developer setting persists across launches.
        argumentValues.append(UITestLaunchArgumentValue(.homePhase2, value: homePhase == .phase2 ? "YES" : "NO"))

        if let homeFeedState {
            argumentValues.append(UITestLaunchArgumentValue(.homeFeedState, value: homeFeedState.launchArgumentValue))
        }

        if !offlineRequests.isEmpty {
            argumentValues.append(UITestLaunchArgumentValue(.offlineRequests, value: UITestOfflineRequest.launchArgumentValue(for: offlineRequests)))
        }

        return argumentValues
    }

    /// Which Community feed the Home tab shows. The "Enable Home Phase 2" developer setting picks it.
    enum HomePhase {
        /// The Community segment hosts the legacy Explore feed, the production default.
        case phase1
        /// The Community segment shows the native Community feed.
        case phase2
    }

    /// What the launch does with the Discover flags, which persist across launches.
    enum DiscoverState: String {
        /// Discover off, the production default.
        case off
        /// Discover on, group B, and the onboarding card shown again.
        case groupB
        /// Leaves the flags as the previous launch left them.
        case keep
    }

    /// Models the persisted onboarding flag that tests need to set before launch.
    enum OnboardingState {
        case completed
        case notCompleted

        fileprivate var launchArgumentValue: String {
            switch self {
            case .completed:
                return "YES"
            case .notCompleted:
                return "NO"
            }
        }
    }

    private let defaultHTTPClientProfile = TestHTTPClientProfile.fixtureStrict.rawValue
    private let defaultLanguageCode = "en"
}

private extension ProcessInfo {
    func value(for launchArgument: UITestLaunchArgument) -> String? {
        arguments.value(for: launchArgument)
    }
}

private extension Array where Element == String {
    func value(for launchArgument: UITestLaunchArgument) -> String? {
        guard let argumentIndex = firstIndex(of: launchArgument.rawValue) else {
            return nil
        }

        let valueIndex = index(after: argumentIndex)
        guard valueIndex < endIndex else {
            return nil
        }

        return self[valueIndex]
    }
}
