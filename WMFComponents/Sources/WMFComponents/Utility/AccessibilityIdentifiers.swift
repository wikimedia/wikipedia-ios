import Foundation

/// Shared accessibility identifiers used by app code, components, and UI tests.
///
/// These strings are an external UI-test contract. Keep them centralized here so app code,
/// components, and tests do not drift when identifiers are renamed or new elements are added.
public enum AccessibilityIdentifiers {
    public enum Article {
        public static let homeButton = "Article Home Button"
        public static let searchButton = "Article Search Button"
        public static let view = "Article View"
    }

    public enum Explore {
        public static let articleCell = "Explore Article Cell"
        public static let view = "Explore View"
    }

    public enum Profile {
        public static let button = "profile-button"
        public static let view = "Profile View"
    }

    public enum Search {
        public static let searchField = "Search Field"
        public static let searchBar = "Search Bar"
        public static let view = "Search View"
    }

    public enum Onboarding {
        public static let addLanguagesButton = "App Onboarding Add Languages Button"
        public static let analyticsLearnMoreButton = "App Onboarding Analytics Learn More Button"
        public static let analyticsView = "App Onboarding Analytics View"
        public static let explorationView = "App Onboarding Exploration View"
        public static let introductionLearnMoreButton = "App Onboarding Introduction Learn More Button"
        public static let introductionView = "App Onboarding Introduction View"
        public static let languagesView = "App Onboarding Languages View"
        public static let nextButton = "App Onboarding Next Button"
        public static let skipButton = "App Onboarding Skip Button"

        public static func preferredLanguage(_ contentLanguageCode: String) -> String {
            "App Onboarding Preferred Language \(contentLanguageCode)"
        }

        public static func primaryLanguage(_ contentLanguageCode: String) -> String {
            "App Onboarding Primary Language \(contentLanguageCode)"
        }
    }

    public enum LanguageSelection {
        public static let allLanguagesTable = "All Languages Table"
        public static let allLanguagesView = "All Languages View"
        public static let languagesTable = "Languages Table"
        public static let languagesView = "Languages View"
        public static let preferredLanguagesAddLanguageButton = "Preferred Languages Add Language Button"
        public static let preferredLanguagesTable = "Preferred Languages Table"
        public static let preferredLanguagesView = "Preferred Languages View"

        public static func allLanguage(_ contentLanguageCode: String) -> String {
            "Language Selection Language \(contentLanguageCode)"
        }

        public static func otherLanguage(_ contentLanguageCode: String) -> String {
            "Language Selection Other Language \(contentLanguageCode)"
        }

        public static func preferredLanguage(_ contentLanguageCode: String) -> String {
            "Language Selection Preferred Language \(contentLanguageCode)"
        }
    }
}

@objc(WMFAccessibilityIdentifier)
@objcMembers
public final class WMFAccessibilityIdentifier: NSObject {
    public static var languageSelectionAllLanguagesTable: String { AccessibilityIdentifiers.LanguageSelection.allLanguagesTable }
    public static var languageSelectionAllLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.allLanguagesView }
    public static var languageSelectionLanguagesTable: String { AccessibilityIdentifiers.LanguageSelection.languagesTable }
    public static var languageSelectionLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.languagesView }
    public static var languageSelectionPreferredLanguagesAddLanguageButton: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesAddLanguageButton }
    public static var languageSelectionPreferredLanguagesTable: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesTable }
    public static var languageSelectionPreferredLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesView }

    public static func languageSelectionAllLanguage(_ contentLanguageCode: String) -> String {
        AccessibilityIdentifiers.LanguageSelection.allLanguage(contentLanguageCode)
    }

    public static func languageSelectionOtherLanguage(_ contentLanguageCode: String) -> String {
        AccessibilityIdentifiers.LanguageSelection.otherLanguage(contentLanguageCode)
    }

    public static func languageSelectionPreferredLanguage(_ contentLanguageCode: String) -> String {
        AccessibilityIdentifiers.LanguageSelection.preferredLanguage(contentLanguageCode)
    }
}
