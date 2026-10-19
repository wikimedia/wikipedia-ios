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
        public static let homeButton = "Root Tab Home Button"
        public static let placesButton = "Root Tab Places Button"
        public static let savedButton = "Root Tab Saved Button"
        public static let searchButton = Search.tabButton
    }

    public enum Home {
        public static let languagePickerButton = "Home Language Picker Button"
        public static let view = "Home View"
    }

    public enum Saved {
        public static let allArticlesEditingToolbarAddToListButton = "Saved All Articles Editing Toolbar Add To List Button"
        public static let allArticlesEditingToolbarUnsaveButton = "Saved All Articles Editing Toolbar Unsave Button"
        public static let allArticlesEmptyView = "Saved All Articles Empty View"
        public static let allArticlesList = "Saved All Articles List"
        public static let deleteReadingListsAlert = "Saved Delete Reading Lists Alert"
        public static let editingCancelButton = "Saved Editing Cancel Button"
        public static let moreButton = "Saved More Button"
        public static let progressView = "Saved Progress View"
        public static let readingListsEmptyView = "Saved Reading Lists Empty View"
        public static let readingListsView = "Saved Reading Lists View"
        public static let rowDeleteSwipeButton = "Saved Row Delete Swipe Button"
        public static let rowShareSwipeButton = "Saved Row Share Swipe Button"
        public static let sortSheet = "Saved Sort Sheet"
        public static let unsaveArticlesAlert = "Saved Unsave Articles Alert"
        public static let view = "Saved View"

        public static func allArticlesRow(_ title: String) -> String {
            "Saved All Articles Row \(title)"
        }

        public static func batchEditToolbarButton(_ actionName: String) -> String {
            "Saved Batch Edit Toolbar \(actionName) Button"
        }

        public static func readingListCell(_ name: String) -> String {
            "Saved Reading List Cell \(name)"
        }

        public static func readingListTag(_ name: String) -> String {
            "Saved Reading List Tag \(name)"
        }
    }

    public enum ReadingListDetail {
        public static let articleCountLabel = "Reading List Detail Article Count Label"
        public static let descriptionTextField = "Reading List Detail Description Text Field"
        public static let editButton = "Reading List Detail Edit Button"
        public static let emptyView = "Reading List Detail Empty View"
        public static let sortButton = "Reading List Detail Sort Button"
        public static let titleTextField = "Reading List Detail Title Text Field"
        public static let view = "Reading List Detail View"

        public static func articleCell(_ title: String) -> String {
            "Reading List Detail Article Cell \(title)"
        }
    }

    public enum CreateReadingList {
        public static let closeButton = "Create Reading List Close Button"
        public static let createButton = "Create Reading List Create Button"
        public static let descriptionTextField = "Create Reading List Description Text Field"
        public static let nameErrorLabel = "Create Reading List Name Error Label"
        public static let nameTextField = "Create Reading List Name Text Field"
        public static let view = "Create Reading List View"
    }

    public enum AddToReadingList {
        public static let closeButton = "Add To Reading List Close Button"
        public static let createNewListButton = "Add To Reading List Create New List Button"
        public static let view = "Add To Reading List View"
    }

    public enum YearInReview {
        public static let closeButton = "Year in Review Close Button"
    }

    public enum Profile {
        public static let button = "profile-button"
        public static let view = "Profile View"
        public static let temporaryAccountUserPageRow = "Profile Temporary Account User Page Row"
        public static let joinWikipediaRow = "Profile Join Wikipedia Row"
    }

    public enum Search {
        public static let clearRecentSearchesButton = "Search Clear Recent Searches Button"
        public static let clearRecentSearchesConfirmButton = "Search Clear Recent Searches Confirm Button"
        public static let recentSearchesView = "Search Recent Searches View"
        public static let searchField = "Search Field"
        public static let semanticSearchEntryPoint = "Search Semantic Search Entry Point"
        public static let semanticSearchEntryPointInfoButton = "Search Semantic Search Entry Point Info Button"
        public static let semanticSearchEntryPointHideButton = "Search Semantic Search Entry Point Hide Button"
        public static let semanticSearchResultsView = "Search Semantic Search Results View"
        public static let semanticSearchResultsCloseButton = "Search Semantic Search Results Close Button"
        public static let semanticSearchResultCard = "Search Semantic Search Result Card"
        public static let semanticSearchFeedback = "Search Semantic Search Feedback"
        public static let semanticSearchFeedbackThumbsUpButton = "Search Semantic Search Feedback Thumbs Up Button"
        public static let semanticSearchFeedbackThumbsDownButton = "Search Semantic Search Feedback Thumbs Down Button"
        public static let semanticSearchFeedbackTextField = "Search Semantic Search Feedback Text Field"
        public static let semanticSearchFeedbackSubmitButton = "Search Semantic Search Feedback Submit Button"
        public static let semanticSearchFeedbackCloseButton = "Search Semantic Search Feedback Close Button"
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
        public static let communityOptionButton = "App Onboarding Community Option Button"
        public static let dataPrivacyView = "App Onboarding Data Privacy View"
        public static let feedPreferenceView = "App Onboarding Feed Preference View"
        public static let introView = "App Onboarding Intro View"
        public static let languagesView = "App Onboarding Languages View"
        public static let learnMoreLink = "App Onboarding Learn More Link"
        public static let loadingView = "App Onboarding Loading View"
        public static let nextButton = "App Onboarding Next Button"
        public static let personalizationIntroView = "App Onboarding Personalization Intro View"
        public static let personalizedOptionButton = "App Onboarding Personalized Option Button"
        public static let privacyLinks = "App Onboarding Privacy Links"
        public static let skipButton = "App Onboarding Skip Button"
    }

    public enum Interests {
        public static let deselectAllButton = "Interests Deselect All Button"
        public static let searchCancelButton = "Interests Search Cancel Button"
        public static let searchField = "Interests Search Field"
        public static let searchResultRow = "Interests Search Result Row"
        public static let view = "Interests View"
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
