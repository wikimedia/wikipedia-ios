import Foundation

// Utilize this class to define localized strings that are used in multiple places in similar contexts.
// There should only be one WMF Localized String function in code for every localization key.
// If the same string value is used in different contexts, use different localization keys.

@objc(WMFCommonStrings)
public class CommonStrings: NSObject {
    @objc public static let articleCountFormat = WMFLocalizedString("places-filter-top-articles-count", value:"{{PLURAL:%1$d|%1$d article|%1$d articles}}", comment: "Describes how many top articles are found in the top articles filter - %1$d is replaced with the number of articles")
    @objc public static let readingListCountFormat = WMFLocalizedString("reading-lists-count", value:"{{PLURAL:%1$d|%1$d reading list|%1$d reading lists}}", comment: "Describes the number of reading lists - %1$d is replaced with the number of reading lists")
    
    @objc public static let shortSavedTitle = WMFLocalizedString("action-saved", value: "Saved", comment: "Short title for the save button in the 'Saved' state - Indicates the article is saved. Please use the shortest translation possible. {{Identical|Saved}}")
    @objc public static let accessibilitySavedTitle = WMFLocalizedString("action-saved-accessibility", value: "Saved. Activate to unsave.", comment: "Accessibility title for the 'Unsave' action {{Identical|Saved}}")
    @objc public static let shortUnsaveTitle = WMFLocalizedString("action-unsave", value: "Unsave", comment: "Short title for the 'Unsave' action. Please use the shortest translation possible. {{Identical|Saved}}")
    
    @objc public static let accessibilityBackTitle = WMFLocalizedString("back-button-accessibility-label", value: "Back", comment: "Accessibility label for a button to navigate back. {{Identical|Back}}");
    
    @objc public static let accessibilitySavedNotification = WMFLocalizedString("action-saved-accessibility-notification", value: "Article saved for later", comment: "Notification spoken after user saves an article for later.")
     @objc public static let accessibilityUnsavedNotification = WMFLocalizedString("action-unsaved-accessibility-notification", value: "Article unsaved", comment: "Notification spoken after user removes an article from Saved articles.")
    
    @objc public static func articleDeletedNotification(articleCount: Int) -> String {
        return String.localizedStringWithFormat(WMFLocalizedString("article-deleted-accessibility-notification", value: "{{PLURAL:%1$d|article|articles}} deleted", comment: "Notification spoken after user deletes an article from the list. %1$d will be replaced with the number of deleted articles."), articleCount)
    }
    
    @objc public static func unsaveArticleAndRemoveFromListsTitle(articleCount: Int) -> String {
        return String.localizedStringWithFormat(WMFLocalizedString("saved-unsave-article-and-remove-from-reading-lists-title", value: "Unsave {{PLURAL:%1$d|article|articles}}?", comment: "Title of the alert action that unsaves a selected article and removes it from all associated reading lists. %1$d will be replaced with the number of articles to be unsaved."), articleCount)
    }
    @objc public static func unsaveArticleAndRemoveFromListsMessage(articleCount: Int) -> String {
        return String.localizedStringWithFormat(WMFLocalizedString("saved-unsave-article-and-remove-from-reading-lists-message", value: "Unsaving {{PLURAL:%1$d|this article will remove it|these articles will remove them}} from all associated reading lists", comment: "Message of the alert action that unsaves a selected article and removes it from all associated reading lists. %1$d will be replaced with the number of articles being unsaved."), articleCount)
    }
    
    @objc public static let shortSaveTitle = WMFLocalizedString("action-save", value: "Save", comment: "Title for the 'Save' action {{Identical|Save}}")
    @objc public static let savedTitle:String = CommonStrings.savedTitle(language: nil)
    @objc public static let saveTitle:String = CommonStrings.saveTitle(language: nil)
    @objc public static let dimImagesTitle = WMFLocalizedString("dim-images", value: "Dim images", comment: "Label for image dimming setting")

    @objc public static let searchTitle = WMFLocalizedString("search-title", value: "Search", comment: "Title for search interface. {{Identical|Search}}")
    @objc public static let settingsTitle = WMFLocalizedString("settings-title", value: "Settings", comment: "Title of the view where app settings are displayed. {{Identical|Settings}}")
    @objc public static let placesTabTitle = WMFLocalizedString("places-title", value: "Places", comment: "Title of the Places screen shown on the places tab.")
    @objc public static let historyTabTitle = WMFLocalizedString("history-title", value: "History", comment: "Title of the history screen shown on history tab {{Identical|History}}")
    @objc public static let exploreTabTitle = WMFLocalizedString("home-title", value: "Explore", comment: "Title for home interface. {{Identical|Explore}}")
    @objc public static let savedTabTitle = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab {{Identical|Saved}}")

    @objc public static let exploreFeedTitle = WMFLocalizedString("welcome-exploration-explore-feed-title", value:"Explore feed", comment:"Title for Explore feed")
    @objc public static let featuredArticleTitle = WMFLocalizedString("explore-featured-article-heading", value: "Featured article", comment: "Text for 'Featured article' header")
    @objc public static let onThisDayTitle = WMFLocalizedString("on-this-day-title", value: "On this day", comment: "Title for the 'On this day' feed section")
    @objc public static let topReadTitle = WMFLocalizedString("places-filter-top-articles", value:"Top read", comment: "Title of places search filter that searches top articles")
    @objc public static let pictureOfTheDayTitle = WMFLocalizedString("explore-potd-heading", value: "Picture of the day", comment: "Text for 'Picture of the day' header");
    @objc public static let randomizerTitle = WMFLocalizedString("explore-randomizer", value: "Randomizer", comment: "Displayed on a button that loads another random article - it's a 'Randomizer'");
    @objc public static let languagesTitle = WMFLocalizedString("languages-settings-title", value: "Languages", comment: "Title for the 'Languages' section in Settings");
    @objc public static let relatedPagesTitle = WMFLocalizedString("explore-because-you-read", value: "Because you read", comment: "Text for 'Because you read' header");
    @objc public static let continueReadingTitle = WMFLocalizedString("explore-continue-reading-heading", value: "Continue reading", comment: "Text for 'Continue Reading' header");

    @objc public static let hideCardTitle = WMFLocalizedString("explore-hide-card-prompt", value: "Hide this card", comment: "Title of button shown for users to confirm the hiding of a suggestion in the explore feed")

    @objc static public func savedTitle(language: String?) -> String {
        return WMFLocalizedString("button-saved-for-later", language: language, value: "Saved for later", comment: "Longer button text for already saved button used in various places.")
    }
    
    @objc static public func saveTitle(language: String?) -> String {
        return WMFLocalizedString("button-save-for-later", language: language, value: "Save for later", comment: "Longer button text for save button used in various places.")
    }
    
    @objc public static let shortShareTitle = WMFLocalizedString("action-share", value: "Share", comment: "Short title for the 'Share' action. Please use the shortest translation possible. {{Identical|Share}}")
    @objc public static let accessibilityShareTitle = WMFLocalizedString("action-share-accessibility", value: "Share", comment: "Accessibility title for the 'Share' action")
    
    @objc public static let accessibilityLanguagesTitle = WMFLocalizedString("action-language-accessibility", value: "Change language", comment: "Accessibility title for the 'Language' toolbar button on articles and talk pages.")
    
    @objc public static let shortReadTitle = WMFLocalizedString("action-read", value: "Read", comment: "Title for the 'Read' action\n{{Identical|Read}}")
    
    @objc public static let dismissButtonTitle = WMFLocalizedString("announcements-dismiss", value: "Dismiss", comment: "Button text indicating a user wants to dismiss an announcement {{Identical|No thanks}}")
    
    @objc public static let textSizeSliderAccessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-text-size-slider", value: "Text size slider", comment: "Accessibility label for the text size slider that adjusts article text size.")
    
    @objc public static let deleteActionTitle = WMFLocalizedString("article-delete", value: "Delete", comment: "Title of the action that deletes the selected articles article.")
    
    @objc public static let removeActionTitle = WMFLocalizedString("action-remove", value: "Remove", comment: "Title of the action that removes the selection from the current context.")

    @objc public static let createNewListTitle = WMFLocalizedString("reading-list-create-new-list-title", value: "Create a new list", comment: "Title for the view in charge of creating a new reading list.")
    @objc public static let moveToReadingListActionTitle = WMFLocalizedString("action-move-to-reading-list", value: "Move to reading list", comment: "Title of the action that moves the selected articles to another reading list")
    @objc public static let addToReadingListActionTitle = WMFLocalizedString("action-add-to-reading-list", value: "Add to reading list", comment: "Title of the action that adds selected articles to a reading list")
    @objc public static let addToReadingListShortActionTitle = WMFLocalizedString("action-add-to-reading-list-short", value: "Add to list", comment: "Shorter title for the action that adds selected articles to a reading list")

    @objc public static let moveToActionTitle = WMFLocalizedString("action-move-to", value: "Move to…", comment: "Title of the action that moves the selection elsewhere.")
    
    @objc public static let addToActionTitle = WMFLocalizedString("action-add-to", value: "Add to…", comment: "Title of the action that adds the selection to something else.")
    
    @objc public static let shareActionTitle = WMFLocalizedString("article-share", value: "Share", comment: "Text of the article list row action shown on swipe which allows the user to choose the sharing option")
    public static let shareMenuTitle = WMFLocalizedString("share-menu-item", value: "Share…", comment:"'Share…' menu item with ellipsis to indicate further actions are required.")

    @objc public static let updateActionTitle = WMFLocalizedString("action-update", value: "Update", comment: "Title of the update action.")
    @objc public static let cancelActionTitle = WMFLocalizedString("action-cancel", value: "Cancel", comment: "Title of the cancel action.")
    @objc public static let retryActionTitle = WMFLocalizedString("action-retry", value: "Retry", comment: "Title of the retry action.")

    @objc public static let sortActionTitle = WMFLocalizedString("action-sort", value: "Sort", comment: "Title of the sort action.")

    @objc public static let sortAlertTitle = WMFLocalizedString("reading-lists-sort-saved-articles", value: "Sort saved articles", comment: "Title of the alert that allows sorting saved articles.")

    @objc public static let nextTitle = WMFLocalizedString("button-next", value: "Next", comment: "Button text for next button used in various places. {{Identical|Next}}")
    @objc public static let skipTitle = WMFLocalizedString("button-skip", value: "Skip", comment: "Button text for skip button used in various places.")
    @objc public static let okTitle = WMFLocalizedString("button-ok", value: "OK", comment: "Button text for ok button used in various places {{Identical|OK}}")
    @objc public static let doneTitle = WMFLocalizedString("description-published-button-title", value: "Done", comment: "Title for description panel done button.")
    
    @objc public static let undo = WMFLocalizedString("action-undo", value: "Undo", comment: "Title text and accessibility label for undo action on buttons or info sheets.")
    @objc public static let redo = WMFLocalizedString("action-redo", value: "Redo", comment: "Title text and accessibility label for redo action on buttons or info sheets.")
    @objc public static let findInPage = WMFLocalizedString("action-find-in-page", value: "Find in page", comment: "Title text and accessibility label for find in page action on buttons or info sheets.")
    @objc public static let readingThemesControls = WMFLocalizedString("article-toolbar-reading-themes-controls-toolbar-item", value: "Reading Themes Controls", comment: "Accessibility label for the Reading Themes Controls article toolbar item")

    public static let welcomePromiseTitle = WMFLocalizedString("description-welcome-promise-title", value:"By starting, I promise not to misuse this feature", comment:"Title text asking user to edit descriptions responsibly")
    @objc public static let gotItButtonTitle = WMFLocalizedString("welcome-explore-tell-me-more-done-button", value: "Got it", comment:"Text for button dismissing detailed explanation of new features")
    public static let getStartedTitle = WMFLocalizedString("welcome-explore-continue-button", value:"Get started", comment:"Text for button for dismissing welcome screens {{Identical|Get started}}")
    
    @objc public static let privacyPolicyURLString = "https://foundation.m.wikimedia.org/wiki/Privacy_policy"
    
    @objc public static let account = WMFLocalizedString("settings-account", value: "Account", comment: "Title for button and page letting user view their account page.")

    @objc public static let myLanguages = WMFLocalizedString("settings-my-languages", value: "My languages", comment: "Title for list of user's preferred languages")
    @objc public static let readingPreferences = WMFLocalizedString("settings-appearance", value: "Reading preferences", comment: "Title of the reading preferences screen.")
    @objc public static let notifications = WMFLocalizedString("settings-notifications", value: "Notifications", comment: "Title for button letting user choose notifications settings. {{Identical|Notification}}")
    
    @objc public static let settingsStorageAndSyncing = WMFLocalizedString("settings-storage-and-syncing-title", value: "Article storage and syncing", comment: "Title of the saved articles storage and syncing settings screen")

    @objc public static let inTheNewsTitle = WMFLocalizedString("in-the-news-title", value:"In the news", comment:"Title for the 'In the news' notification & feed section")

    @objc public static let wikipediaLanguages = WMFLocalizedString("languages-wikipedia", value: "Wikipedia languages", comment: "Title for list of Wikipedia languages")
    
    @objc public static let unknownError = WMFLocalizedString("error-unknown", value: "An unknown error occurred", comment: "Message displayed when an unknown error occurred")
    
    @objc public static let readingListsDefaultListTitle = WMFLocalizedString("reading-lists-default-list-title", value: "Saved", comment: "The title of the default saved pages list {{Identical|Saved}}")

    @objc public static let localizedEnableLocationTitle = WMFLocalizedString("places-enable-location-title", value:"Explore articles near your location by enabling Location Access", comment:"Explains that you can explore articles near you by enabling location access. \"Location\" should be the same term, which is used in the device settings, under \"Privacy\".")
    @objc public static let localizedEnableLocationExploreTitle = WMFLocalizedString("explore-enable-location-title", value:"Explore articles near your current location", comment:"Explains that you can explore articles near your current location. \"Location\" should be the same term, which is used in the device settings, under \"Privacy\".")
    @objc public static let localizedEnableLocationDescription = WMFLocalizedString("places-enable-location-description", value:"Access to your location is available only when the app or one of its features is visible on your screen.", comment:"Describes that access to your location is only used when the app or one of its features is on the screen")
    @objc public static let localizedEnableLocationButtonTitle = WMFLocalizedString("places-enable-location-action-button-title", value:"Enable location", comment:"Button title to enable location access")
    @objc public static let nearbyFooterTitle = WMFLocalizedString("home-nearby-footer", value: "More places near your location", comment: "Footer for presenting user option to see longer list of nearby articles.")
    
    @objc public static let readingListLoginSubtitle =  WMFLocalizedString("reading-list-login-subtitle", value:"Log in or create an account to allow your saved articles and reading lists to be synced across devices and saved to your user preferences.", comment:"Subtitle explaining that saved articles and reading lists can be synced across Wikipedia apps.")
    @objc public static let readingListLoginButtonTitle = WMFLocalizedString("reading-list-login-button-title", value:"Log in to sync your saved articles", comment:"Title for button to login to sync saved articles and reading lists.")
    
    @objc public static let readingListDoNotKeepSubtitle =  WMFLocalizedString("reading-list-do-not-keep-button-title", value:"No, delete articles from device", comment:"Title for button to remove saved articles from device.")

    @objc public static let readingListsDefaultListDescription = WMFLocalizedString("reading-lists-default-list-description", value: "Default list for your saved articles", comment: "The description of the default saved pages list.")
    
    @objc public static let readingListsEntryLimitReachedFormat = WMFLocalizedString("reading-list-entry-limit-reached", value: "{{PLURAL:%1$d|Article|Articles}} cannot be added to this list. You have reached the limit of %2$d articles per reading list for %3$@", comment: "Informs the user that adding the selected articles to their reading list would put them over the limit. %1$d will be replaced with the number of articles the user is trying to add. %2$d will be replaced with the maximum number of articles allowed per list. %3$@ will be replaced with the name of the list.")
    @objc public static let readingListsListLimitReachedFormat = WMFLocalizedString("reading-list-list-limit-reached", value: "You have reached the limit of %1$d reading lists per account", comment: "Informs the user that they have reached the allowed limit of reading lists per account. %1$d will be replaced with the maximum number of allowed reading lists")
     @objc public static let eraseAllSavedArticles = WMFLocalizedString("settings-storage-and-syncing-erase-saved-articles-title", value: "Erase saved articles", comment: "Title of the settings option that enables erasing saved articles")
    
    @objc public static let keepSavedArticlesOnDeviceMessage = WMFLocalizedString("reading-list-keep-subtitle", value: "There are articles synced to your Wikipedia account. Would you like to keep them on this device after you log out?", comment: "Subtitle asking if synced articles should be kept on device after logout.")
    
    @objc public static let closeButtonAccessibilityLabel = WMFLocalizedString("close-button-accessibility-label", value: "Close", comment: "Accessibility label for a button that closes a dialog. {{Identical|Close}}")

    @objc public static let onTitle = WMFLocalizedString("explore-feed-preferences-feed-card-visibility-global-cards-on", value: "On", comment: "Text for Explore feed card setting indicating that the global feed card is active")
    @objc public static let onAllTitle = WMFLocalizedString("explore-feed-preferences-feed-card-visibility-all-languages-on", value: "On all", comment: "Text for Explore feed card setting indicating that the feed card is active in all preferred languages")
    @objc public static let offTitle = WMFLocalizedString("explore-feed-preferences-feed-card-visibility-all-languages-off", value: "Off", comment: "Text for Explore feed card setting indicating that the feed card is hidden in all preferred languages")
    @objc public static func onTitle(_ count: Int) -> String {
        return String.localizedStringWithFormat(WMFLocalizedString("explore-feed-preferences-feed-card-visibility-languages-count", value:"On %1$d", comment: "Text for Explore feed card setting indicating the number of languages it's visible in - %1$d is replaced with the number of languages"), count)
    }

    @objc public static let turnOnExploreTabTitle = WMFLocalizedString("explore-feed-preferences-turn-on-explore-tab-title", value: "Turn on the Explore tab?", comment: "Title for alert that allows users to turn on the Explore tab")
    @objc public static let turnOnExploreActionTitle = WMFLocalizedString("explore-feed-preferences-turn-on-explore-tab-action-title", value: "Turn on Explore", comment: "Title for action that allows users to turn on the Explore tab")
    @objc public static let customizeExploreFeedTitle = WMFLocalizedString("explore-feed-preferences-customize-explore-feed-action-title", value: "Customize Explore feed", comment: "Title for action that allows users to go to the Explore feed settings screen")

    @objc public static let revertedEditTitle = WMFLocalizedString("reverted-edit-title", value: "Reverted edit", comment: "Title for notification informing user that their edit was reverted.")

    @objc public static let noInternetConnection = WMFLocalizedString("no-internet-connection", value: "No internet connection", comment: "String used in various places to indicate no internet connection")
    
    // REMINDER: do not delete the app store strings below. We're not using them anywhere within the app itself but we need them to remain so they get upstreamed into TWN. ("localizations.swift copies the non-EN translations of these strings into respective Fastlane "Localized Metadata" files. See: https://docs.fastlane.tools/actions/deliver/)
    @objc public static let appStoreSubtitle = WMFLocalizedString("app-store-subtitle", value: "The free encyclopedia", comment: "Subtitle describing the app for the app store")
    @objc public static let appStoreShortDescription = WMFLocalizedString("app-store-short-description", value: "Download the Wikipedia app to explore places near you, sync articles to read offline and customize your reading experience.", comment: "Short description of the app for the app store")
    @objc public static let appStoreReleaseNotes = WMFLocalizedString("app-store-release-notes", value: "Fully customizable and easier to read Explore feed. Localization, performance improvements and bug fixes.", comment: "Short summary of what is new in this version of the app for the app store")
    @objc public static let appStoreKeywords = WMFLocalizedString("app-store-keywords", value: "Wikipedia, reference, wiki, encyclopedia, info, knowledge, research, information, explore, learn", comment: "Short list of keywords describing the app for the app store. It is required that these are individual words, not phrases, and are comma separated.")
    
    @objc public static let editAttribution = WMFLocalizedString("wikitext-upload-save-anonymously-warning", value: "Edits will be attributed to the IP address of your device. If you %1$@ you will have more privacy.", comment: "Button sub-text informing user or draw-backs of not signing in before saving wikitext. Parameters:\n* %1$@ - sign in button text")

    @objc public static let editSignIn = WMFLocalizedString("wikitext-upload-save-sign-in", value: "Log in", comment: "{{Identical|Log in}}")
    
    public static let genericErrorDescription = WMFLocalizedString("fetcher-error-generic", value: "Something went wrong. Please try again later.", comment: "Error shown to the user for generic errors with no clear recovery steps for the user.")

    public static let insertMediaTitle = WMFLocalizedString("insert-media-title", value: "Insert media", comment: "Title for the view in charge of inserting media into an article")
    
    public static let publishTitle = WMFLocalizedString("button-publish", value: "Publish", comment: "Button text for publish button used in various places. {{Identical|Publish}}")
    public static let logoutTitle = WMFLocalizedString("main-menu-account-logout", value: "Log out", comment: "Button text for logging out.")

    public static let insertLinkTitle = WMFLocalizedString("insert-link-title", value: "Insert link", comment: "Title for the Insert link screen")
    public static let editLinkTitle = WMFLocalizedString("edit-link-title", value: "Edit link", comment: "Title for the Edit link screen")
    
    public static let talkPageNewBannerTitle = WMFLocalizedString("talk-page-new-banner-title", value: "Please be kind", comment: "Title text on banner that appears once user posts a new reply or discussion topic on their talk page.")
    
    public static let talkPageNewBannerSubtitle = WMFLocalizedString("talk-page-new-banner-subtitle", value: "Remember, we are all humans here", comment: "Subtitle text on banner that appears once user posts a new reply or discussion topic on their talk page.")

    public static let accessibilityClearTitle = WMFLocalizedString("clear-title-accessibility-label", value: "Clear", comment: "Accessibility label title for action that clears text")
    
    public static let successfullyPublishedDiscussion = WMFLocalizedString("talk-page-new-topic-success-text", value: "Your discussion was successfully published", comment: "Banner text that appears after a new discussion was successfully published on a talk page.")
    
    public static let successfullyPublishedReply = WMFLocalizedString("talk-page-new-reply-success-text", value: "Your reply was successfully published", comment: "Banner text that appears after a new reply was successfully published on a talk page discussion.")
    
    public static let defaultThemeDisplayName = WMFLocalizedString("theme-default-display-name", value: "Default", comment: "Default theme name presented to the user")
    
    public static let diffSingleLineFormat = WMFLocalizedString("diff-single-line-format", value:"Line %1$d", comment:"Label in diff to indicate how many lines a change section encompases. This format is for a single change line. %1$d is replaced by the change line number.")
    
    public static let diffMultiLineFormat = WMFLocalizedString("diff-multi-line-format", value:"Lines %1$d - %2$d", comment:"Label in diff to indicate how many lines a change section encompases. This format is for multiple change lines. %1$d is replaced by the starting line number and %2$d is replaced by the ending line number.")

    public static let compareTitle = WMFLocalizedString("page-history-compare-title", value: "Compare", comment: "Title for action button that allows users to contrast different items")
    public static let maxRevisionsSelectedWarningTitle = WMFLocalizedString("page-history-revisions-comparison-warning", value: "Only two revisions can be selected", comment: "Text telling the user how many revisions can be selected for comparison")
    
    public static let loginOrCreateAccountTitle = WMFLocalizedString("reading-list-login-or-create-account-button-title", value:"Log in or create account", comment:"Title for button to login or create account.")
    
    @objc public static let diffErrorTitle = WMFLocalizedString("diff-revision-error-title", value: "Unable to load revision", comment: "Text for placeholder label visible when there has been an error while fetching the diff.");

    @objc public static let minorEditTitle = WMFLocalizedString("page-history-revision-minor-edit-accessibility-label", value: "Minor edit", comment: "Accessibility label text used if edit was minor")

    @objc public static let authorTitle = WMFLocalizedString("page-history-revision-author-accessibility-label", value: "Author: %@", comment: "Accessibility label text telling the user who authored a revision. %@ is replaced with the author.")
    
    @objc public static let unknownTitle = WMFLocalizedString("unknown-generic-text", value: "Unknown", comment: "Default text used in places where no contextual information is provided")
    
    public static func aboutThisArticleTitle(with language: String) -> String {
        return WMFLocalizedString("article-about-title", language: language, value: "About this article", comment: "The text that is displayed before the 'about' section at the bottom of an article")
    }
    public static func readMoreTitle(with language: String) -> String {
        return WMFLocalizedString("article-read-more-title", language: language, value: "Read more", comment: "The text that is displayed before the read more section at the bottom of an article {{Identical|Read more}}")
    }
}


// Temporarily keep these strings to sync to PCS for https://phabricator.wikimedia.org/T246529
// Remove once is https://phabricator.wikimedia.org/T246659 resolved

//let addTitleDescription = WMFLocalizedString("description-add-link-title", language: language, value: "Add title description", comment: "Text for link for adding a title description")
//let tableInfoboxTitle = WMFLocalizedString("info-box-title", language: language, value: "Quick Facts", comment: "The title of infoboxes – in collapsed and expanded form")
//let tableOtherTitle = WMFLocalizedString("table-title-other", language: language, value: "More information", comment: "The title of non-info box tables - in collapsed and expanded form {{Identical|More information}}")
//let tableFooterTitle = WMFLocalizedString("info-box-close-text", language: language, value: "Close", comment: "The text for telling users they can tap the bottom of the info box to close it {{Identical|Close}}")
//let readMoreHeading = CommonStrings.readMoreTitle(with: language).uppercased(with: locale)
//let licenseString = String.localizedStringWithFormat(WMFLocalizedString("license-footer-text", language: language, value: "Content is available under %1$@ unless otherwise noted.", comment: "Marker at page end for who last modified the page when anonymous. %1$@ is a relative date such as '2 months ago' or 'today'."), "$1")
//let licenseSubstitutionString = WMFLocalizedString("license-footer-name", language: language, value: "CC BY-SA 3.0", comment: "License short name; usually leave untranslated as CC-BY-SA 3.0 {{Identical|CC BY-SA}}")
//let viewInBrowserString = WMFLocalizedString("view-in-browser-footer-link", language: language, value: "View article in browser", comment: "Link to view article in browser")
//let menuHeading = CommonStrings.aboutThisArticleTitle(with: language).uppercased(with: locale)
//let menuLanguagesTitle = String.localizedStringWithFormat(WMFLocalizedString("page-read-in-other-languages", language: language, value: "Available in {{PLURAL:%1$d|%1$d other language|%1$d other languages}}", comment: "Label for button showing number of languages an article is available in. %1$@ will be replaced with the number of languages"), languageCount)
//let menuLastEditedTitle: String
//if let lastModified = lastModified {
//    let days = NSCalendar.wmf_gregorian().wmf_days(from: lastModified, to: Date())
//    menuLastEditedTitle = String.localizedStringWithFormat(WMFLocalizedString("page-last-edited",  language: language, value: "{{PLURAL:%1$d|0=Updated today|1=Updated yesterday|Updated %1$d days ago}}", comment: "Relative days since an article was last edited. 0 = today, singular = yesterday. %1$d will be replaced with the number of days ago."), days)
//} else {
//}
//let menuLastEditedSubtitle = WMFLocalizedString("page-edit-history", language: language, value: "View edit history", comment: "Label for button used to show an article's complete edit history")
//let menuTalkPageTitle = WMFLocalizedString("page-talk-page",  language: language, value: "View talk page", comment: "Label for button linking out to an article's talk page")
// WMFLocalizedString("page-talk-page-subtitle", value: "Discuss improvements to this article", comment: "Subtitle for button linking out to an article's talk page")

//let menuPageIssuesTitle = WMFLocalizedString("page-issues", language: language, value: "View page issues", comment: "Label for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates). {{Identical|Page issue}}")
// WMFLocalizedString("page-issues-subtitle", value: "Alerts about subpar or problematic content", comment: "Subtitle for the button that shows the \"Page issues\" dialog, where information about the imperfections of the current page is provided (by displaying the warning/cleanup templates).")
//let menuDisambiguationTitle = WMFLocalizedString("page-similar-titles", language: language, value: "Similar pages", comment: "Label for button that shows a list of similar titles (disambiguation) for the current page")
//let menuCoordinateTitle = WMFLocalizedString("page-location", language: language, value: "View on a map", comment: "Label for button used to show an article on the map")
