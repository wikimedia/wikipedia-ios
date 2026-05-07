import Foundation

/// Shared accessibility identifiers used by app code and UI tests.
///
/// These strings are an external UI-test contract. Keep them centralized here so app code
/// and tests do not drift when identifiers are renamed or new elements are added.
enum AccessibilityIdentifiers {
    enum Explore {
        static let view = "Explore View"
    }

    enum Profile {
        static let button = "profile-button"
        static let view = "Profile View"
    }

    enum Onboarding {
        static let addLanguagesButton = "App Onboarding Add Languages Button"
        static let analyticsLearnMoreButton = "App Onboarding Analytics Learn More Button"
        static let analyticsView = "App Onboarding Analytics View"
        static let explorationView = "App Onboarding Exploration View"
        static let introductionLearnMoreButton = "App Onboarding Introduction Learn More Button"
        static let introductionView = "App Onboarding Introduction View"
        static let languagesView = "App Onboarding Languages View"
        static let skipButton = "App Onboarding Skip Button"

        static func preferredLanguage(_ contentLanguageCode: String) -> String {
            "App Onboarding Preferred Language \(contentLanguageCode)"
        }

        static func primaryLanguage(_ contentLanguageCode: String) -> String {
            "App Onboarding Primary Language \(contentLanguageCode)"
        }
    }

    enum LanguageSelection {
        static let allLanguagesTable = "All Languages Table"
        static let allLanguagesView = "All Languages View"
        static let languagesTable = "Languages Table"
        static let languagesView = "Languages View"
        static let preferredLanguagesAddLanguageButton = "Preferred Languages Add Language Button"
        static let preferredLanguagesTable = "Preferred Languages Table"
        static let preferredLanguagesView = "Preferred Languages View"

        static func allLanguage(_ contentLanguageCode: String) -> String {
            "Language Selection Language \(contentLanguageCode)"
        }

        static func otherLanguage(_ contentLanguageCode: String) -> String {
            "Language Selection Other Language \(contentLanguageCode)"
        }

        static func preferredLanguage(_ contentLanguageCode: String) -> String {
            "Language Selection Preferred Language \(contentLanguageCode)"
        }
    }
}

// Expose to objc as needed
@objc(WMFAccessibilityIdentifier)
@objcMembers
final class WMFAccessibilityIdentifier: NSObject {
    static var languageSelectionAllLanguagesTable: String { AccessibilityIdentifiers.LanguageSelection.allLanguagesTable }
    static var languageSelectionAllLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.allLanguagesView }
    static var languageSelectionLanguagesTable: String { AccessibilityIdentifiers.LanguageSelection.languagesTable }
    static var languageSelectionLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.languagesView }
    static var languageSelectionPreferredLanguagesAddLanguageButton: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesAddLanguageButton }
    static var languageSelectionPreferredLanguagesTable: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesTable }
    static var languageSelectionPreferredLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesView }

    static func languageSelectionAllLanguage(_ contentLanguageCode: String) -> String {
        AccessibilityIdentifiers.LanguageSelection.allLanguage(contentLanguageCode)
    }

    static func languageSelectionOtherLanguage(_ contentLanguageCode: String) -> String {
        AccessibilityIdentifiers.LanguageSelection.otherLanguage(contentLanguageCode)
    }

    static func languageSelectionPreferredLanguage(_ contentLanguageCode: String) -> String {
        AccessibilityIdentifiers.LanguageSelection.preferredLanguage(contentLanguageCode)
    }
}
