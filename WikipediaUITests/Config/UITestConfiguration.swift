import Foundation
import XCTest

/// Provides access to the current UI-test launch configuration from XCTest helpers.
extension XCTestCase {
    var uiTestConfiguration: UITestConfiguration {
        UITestConfiguration()
    }
}

/// Captures the launch-time settings that make UI tests deterministic across theme, language, onboarding state, and network profile.
struct UITestConfiguration {
    var onboardingState: OnboardingState
    let httpClientProfile: String
    let resetsPreferredLanguages: Bool
    let suppressesActivityTabOnboarding: Bool
    let suppressesGamesAnnouncement: Bool
    let themeName: String?
    let languageCode: String

    var isRightToLeft: Bool {
        NSLocale.characterDirection(forLanguage: languageCode) == .rightToLeft
    }

    init(
        onboardingState: OnboardingState = .completed,
        resetsPreferredLanguages: Bool = true,
        suppressesActivityTabOnboarding: Bool = true,
        suppressesGamesAnnouncement: Bool = true
    ) {
        self.onboardingState = onboardingState
        self.httpClientProfile = ProcessInfo.processInfo.value(for: .httpClientProfile) ?? defaultHTTPClientProfile
        self.themeName = ProcessInfo.processInfo.value(for: .appThemeName)
        self.resetsPreferredLanguages = resetsPreferredLanguages
        self.suppressesActivityTabOnboarding = suppressesActivityTabOnboarding
        self.suppressesGamesAnnouncement = suppressesGamesAnnouncement
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

        argumentValues.append(UITestLaunchArgumentValue(.appleLanguages, value: "(\(languageCode))"))
        argumentValues.append(UITestLaunchArgumentValue(.httpClientProfile, value: httpClientProfile))
        argumentValues.append(UITestLaunchArgumentValue(.hideTipsForTesting, value: "YES"))
        argumentValues.append(UITestLaunchArgumentValue(.didShowOnboarding, value: onboardingState.launchArgumentValue))

        return argumentValues
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
