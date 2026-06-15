import Foundation

/// Shared accessibility identifiers used by app code, components, and UI tests.
///
/// These strings are an external UI-test contract. Keep them centralized here so app code,
/// components, and tests do not drift when identifiers are renamed or new elements are added.
public enum AccessibilityIdentifiers {
    public enum Article {
        public static let findInPageButton = "Article Find In Page Button"
        public static let findInPageClearButton = "Article Find In Page Clear Button"
        public static let findInPageCloseButton = "Article Find In Page Close Button"
        public static let findInPageMatchLabel = "Article Find In Page Match Label"
        public static let findInPageNextButton = "Article Find In Page Next Button"
        public static let findInPagePreviousButton = "Article Find In Page Previous Button"
        public static let findInPageTextField = "Article Find In Page Text Field"
        public static let findInPageView = "Article Find In Page View"
        public static let homeButton = "Article Home Button"
        public static let languagesButton = "Article Languages Button"
        public static let leadImage = "Article Lead Image"
        public static let linkPreview = "Article Link Preview"
        public static let moreButton = "Article More Button"
        public static let readingThemesBlackButton = "Article Reading Themes Black Button"
        public static let readingThemesBrightnessSlider = "Article Reading Themes Brightness Slider"
        public static let readingThemesDarkButton = "Article Reading Themes Dark Button"
        public static let readingThemesLightButton = "Article Reading Themes Light Button"
        public static let readingThemesSepiaButton = "Article Reading Themes Sepia Button"
        public static let readingThemesTextSizeSlider = "Article Reading Themes Text Size Slider"
        public static let readingThemesView = "Article Reading Themes View"
        public static let saveButton = "Article Save Button"
        public static let shareButton = "Article Share Button"
        public static let searchButton = "Article Search Button"
        public static let tableOfContentsButton = "Article Table of Contents Button"
        public static let tableOfContentsView = "Article Table of Contents View"
        public static let themeButton = "Article Theme Button"
        public static let view = "Article View"

        public static func tableOfContentsItem(_ anchor: String) -> String {
            "Article Table of Contents Item \(anchor)"
        }
    }

    public enum Explore {
        public static let articleCell = "Explore Article Cell"
        public static let pictureOfTheDayCell = "Explore Picture of the Day Cell"
        public static let view = "Explore View"
    }

    public enum RootTab {
        public static let activityButton = "Root Tab Activity Button"
        public static let exploreButton = "Root Tab Explore Button"
        public static let homeButton = "Root Tab Home Button"
        public static let placesButton = "Root Tab Places Button"
        public static let savedButton = "Root Tab Saved Button"
        public static let searchButton = Search.tabButton
    }

    public enum Home {
        public static let languagePickerButton = "Home Language Picker Button"
    }

    public enum Profile {
        public static let button = "profile-button"
        public static let view = "Profile View"
    }

    public enum Search {
        public static let clearRecentSearchesButton = "Search Clear Recent Searches Button"
        public static let clearRecentSearchesConfirmButton = "Search Clear Recent Searches Confirm Button"
        public static let recentSearchesView = "Search Recent Searches View"
        public static let searchField = "Search Field"
        public static let searchBar = "Search Bar"
        public static let tabButton = "Search Tab Button"
        public static let view = "Search View"

        public static func recentSearchTerm(_ term: String) -> String {
            "Search Recent Term \(term)"
        }

        public static func result(_ title: String) -> String {
            "Search Result \(title)"
        }
    }

    public enum Tabs {
        public static let button = "Tabs Button"
        public static let view = "Tabs View"
    }

    public enum ImageGallery {
        public static let closeButton = "Image Gallery Close Button"
        public static let image = "Image Gallery Image"
        public static let loadingIndicator = "Image Gallery Loading Indicator"
        public static let shareButton = "Image Gallery Share Button"
        public static let view = "Image Gallery View"
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
    }

    public enum LanguageSelection {
        public static let allLanguagesView = "All Languages View"
        public static let languagesView = "Languages View"
        public static let preferredLanguagesAddLanguageButton = "Preferred Languages Add Language Button"
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
    public static var imageGalleryCloseButton: String { AccessibilityIdentifiers.ImageGallery.closeButton }
    public static var imageGalleryImage: String { AccessibilityIdentifiers.ImageGallery.image }
    public static var imageGalleryLoadingIndicator: String { AccessibilityIdentifiers.ImageGallery.loadingIndicator }
    public static var imageGalleryShareButton: String { AccessibilityIdentifiers.ImageGallery.shareButton }
    public static var imageGalleryView: String { AccessibilityIdentifiers.ImageGallery.view }

    public static var languageSelectionAllLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.allLanguagesView }
    public static var languageSelectionLanguagesView: String { AccessibilityIdentifiers.LanguageSelection.languagesView }
    public static var languageSelectionPreferredLanguagesAddLanguageButton: String { AccessibilityIdentifiers.LanguageSelection.preferredLanguagesAddLanguageButton }
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
