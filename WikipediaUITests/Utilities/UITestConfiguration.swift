import Foundation
import XCTest

extension XCTestCase {
    var uiTestConfiguration: UITestConfiguration {
        UITestConfiguration()
    }
}

struct UITestConfiguration {
    var onboardingState: OnboardingState
    let resetsPreferredLanguages: Bool
    let themeName: String?
    let languageCode: String

    var isRightToLeft: Bool {
        NSLocale.characterDirection(forLanguage: languageCode) == .rightToLeft
    }

    init(
        onboardingState: OnboardingState = .completed,
        resetsPreferredLanguages: Bool = true,
    ) {
        self.onboardingState = onboardingState
        self.themeName = ProcessInfo.processInfo.value(for: .appThemeName)
        self.resetsPreferredLanguages = resetsPreferredLanguages
        self.languageCode = ProcessInfo.processInfo.value(for: .uiTestLanguageCode) ?? Self.defaultLanguageCode
    }

    var launchArguments: [UITestLaunchArgumentValue] {
        var argumentValues: [UITestLaunchArgumentValue] = []

        if let themeName {
            argumentValues.append(UITestLaunchArgumentValue(.appThemeName, value: themeName))
        }

        if resetsPreferredLanguages {
            argumentValues.append(UITestLaunchArgumentValue(.resetPreferredLanguages, value: "YES"))
        }

        argumentValues.append(UITestLaunchArgumentValue(.uiTestLanguageCode, value: languageCode))
        argumentValues.append(UITestLaunchArgumentValue(.didShowOnboarding, value: onboardingState.launchArgumentValue))

        return argumentValues
    }

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

    private static let defaultLanguageCode = "en"
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
