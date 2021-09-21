import Foundation

// Utilize this class to define localized strings that are used in multiple places in similar contexts.
// There should only be one WMF Localized String function in code for every localization key.
// If the same string value is used in different contexts, use different localization keys.

@objc(WMFCommonStrings)
public class CommonStrings: NSObject {
    @objc public static let plainWikipediaName = CommonStrings.plainWikipediaName()
    @objc public static func plainWikipediaName(with languageCode: String? = nil) -> String {
        WMFLocalizedString("about-wikipedia", languageCode: languageCode, value:"Wikipedia", comment: "Wikipedia {{Identical|Wikipedia}}")
    }

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
    @objc public static let savedTitle:String = CommonStrings.savedTitle(languageCode: nil)
    @objc public static let saveTitle:String = CommonStrings.saveTitle(languageCode: nil)
    @objc public static let dimImagesTitle = WMFLocalizedString("dim-images", value: "Dim images", comment: "Label for image dimming setting")

    @objc public static let searchTitle = WMFLocalizedString("search-title", value: "Search", comment: "Title for search interface. {{Identical|Search}}")
    @objc public static let settingsTitle = WMFLocalizedString("settings-title", value: "Settings", comment: "Title of the view where app settings are displayed. {{Identical|Settings}}")
    @objc public static let placesTabTitle = WMFLocalizedString("places-title", value: "Places", comment: "Title of the Places screen shown on the places tab.")
    @objc public static let historyTabTitle = WMFLocalizedString("history-title", value: "History", comment: "Title of the history screen shown on history tab {{Identical|History}}")
    @objc public static let exploreTabTitle = WMFLocalizedString("home-title", value: "Explore", comment: "Title for home interface. {{Identical|Explore}}")
    @objc public static let savedTabTitle = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab {{Identical|Saved}}")

    @objc public static let notificationsCenterTitle = WMFLocalizedString("notifications-center-title", value: "Notifications", comment: "Title for Notifications Center interface.")

    @objc public static let exploreFeedTitle = WMFLocalizedString("welcome-exploration-explore-feed-title", value:"Explore feed", comment:"Title for Explore feed")
    @objc public static let featuredArticleTitle = WMFLocalizedString("explore-featured-article-heading", value: "Featured article", comment: "Text for 'Featured article' header")
    @objc public static let onThisDayTitle = CommonStrings.onThisDayTitle()
    @objc public static func onThisDayTitle(with languageCode: String? = nil) -> String {
        WMFLocalizedString("on-this-day-title", languageCode: languageCode, value: "On this day", comment: "Title for the 'On this day' feed section")
    }
    @objc public static let topReadTitle = WMFLocalizedString("places-filter-top-articles", value:"Top read", comment: "Title of places search filter that searches top articles")
    @objc public static let pictureOfTheDayTitle = WMFLocalizedString("explore-potd-heading", value: "Picture of the day", comment: "Text for 'Picture of the day' header");
    @objc public static let randomizerTitle = WMFLocalizedString("explore-randomizer", value: "Randomizer", comment: "Displayed on a button that loads another random article - it's a 'Randomizer'");
    @objc public static let languagesTitle = WMFLocalizedString("languages-settings-title", value: "Languages", comment: "Title for the 'Languages' section in Settings");
    @objc public static let relatedPagesTitle = WMFLocalizedString("explore-because-you-read", value: "Because you read", comment: "Text for 'Because you read' header");
    @objc public static let continueReadingTitle = WMFLocalizedString("explore-continue-reading-heading", value: "Continue reading", comment: "Text for 'Continue Reading' header");

    @objc public static let hideCardTitle = WMFLocalizedString("explore-hide-card-prompt", value: "Hide this card", comment: "Title of button shown for users to confirm the hiding of a suggestion in the explore feed")

    @objc static public func savedTitle(languageCode: String?) -> String {
        return WMFLocalizedString("button-saved-for-later", languageCode: languageCode, value: "Saved for later", comment: "Longer button text for already saved button used in various places.")
    }

    @objc static public func saveTitle(languageCode: String?) -> String {
        return WMFLocalizedString("button-save-for-later", languageCode: languageCode, value: "Save for later", comment: "Longer button text for save button used in various places.")
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

    public static func aboutThisArticleTitle(with languageCode: String) -> String {
        return WMFLocalizedString("article-about-title", languageCode: languageCode, value: "About this article", comment: "The text that is displayed before the 'about' section at the bottom of an article")
    }
    public static func readMoreTitle(with languageCode: String) -> String {
        return WMFLocalizedString("article-read-more-title", languageCode: languageCode, value: "Read more", comment: "The text that is displayed before the read more section at the bottom of an article {{Identical|Read more}}")
    }

    public static let revisionMadeFormat = WMFLocalizedString("page-history-revision-time-accessibility-label", value: "Revision made %@", comment: "Label text telling the user what time revision was made - %@ is replaced with the time")

    public static let compareRevisionsTitle = WMFLocalizedString("diff-compare-header-heading", value: "Compare Revisions", comment: "Heading label in header when comparing two revisions.")

    //Article As A Living Doucment Strings - for some reason build script doesn't auto generate these when used directly in SignificantEventsViewModels.swift

    public static let viewFullHistoryText = WMFLocalizedString("aaald-view-full-history-button", value: "View full article history", comment: "Text displayed in a button for pushing to the full article history view on the article as a living document screen.")

    static let smallChangeDescription = WMFLocalizedString("aaald-small-change-description",
        value:"{{PLURAL:%1$d|0=No small changes made|%1$d small change made|%1$d small changes made}}",
        comment:"Describes how many small changes are batched together in the article as a living document timeline view. %1$d is replaced with the number of small changes.")

    static let newTalkTopicDescriptionFormat = WMFLocalizedString("aaald-new-talk-topic-description-format", value: "%1$@ about this article", comment: "Title displayed in an article as a living document timeline cell and content insert explaining that a new article talk page topic has been posted. %1$@ is replaced by `New discussion` text.")
    static let newTalkTopicDiscussion = WMFLocalizedString("aaald-new-discussion", value: "New discussion", comment: "Portion of title displayed in article as a living document timeline cell and content insert explaining that a new article talk page topic has been posted.")

    static let vandalismRevertDescription = WMFLocalizedString("aaald-vandalism-revert-description", value: "Suspected Vandalism reverted", comment: "Title displayed in an article as a living document timeline cell explaining that a vandalism revision was reverted.")

    static let multipleChangesMadeDescription = WMFLocalizedString("aaald-multiple-changes-description", value: "Multiple changes made", comment: "Title displayed in article as a living document content insert explaining that multiple changes were made in a revision.")

    static let addedTextDescription = WMFLocalizedString("aaald-added-text-description-2", value:"%1$@ added", comment:"Title displayed in an article as a living document cell explaining that a revision has a certain number of characters added. %1$@ is replaced by a formatted string representing characters added.")

    static let deletedTextDescription = WMFLocalizedString("aaald-deleted-text-description-2", value:"%1$@ deleted", comment:"Title displayed in an article as a living document cell explaining that a revision has a certain number of characters deleted. %1$@ is replaced by a formatted string representing characters deleted.")

    static let charactersTextDescription = WMFLocalizedString("aaald-characters-text-description", value:"{{PLURAL:%1$d|0=characters|character|characters}}",
                                                              comment:"Displayed in an article as a living document cell explaining that a revision has a certain number of characters added or deleted. %1$d is the number of characters added or deleted.")

    static let articleDescriptionUpdatedDescription = WMFLocalizedString("aaald-article-description-updated-description", value:"Article description updated",
    comment:"Title displayed in an article as a living document cell explaining that an article's description was updated in a revision.")

    static let singleReferenceAddedDescription = WMFLocalizedString("aaald-single-reference-added-description", value:"Reference added",
    comment:"Title displayed in an article as a living document timeline cell when a reference was added (and no other changes) to a revision.")

    static let multipleReferencesAddedDescription = WMFLocalizedString("aaald-multiple-references-added-description", value:"Multiple references added",
                                                                       comment:"Title displayed in an article as a living document cell when multiple references were added (and no other changes) to a revision.")

    static let numericalMultipleReferencesAddedDescription = WMFLocalizedString("aaald-numerical-multiple-references-added-description", value:"{{PLURAL:%1$d|0=0 references|%1$d reference|%1$d references}} added",
    comment:"Title displayed in an article as a living document cell explaining that multiple references were added to a revision. This string is used alongside other changes types like added characters. %1$d is replaced with the number of references.")

    static let oneSectionDescription = WMFLocalizedString("aaald-one-section-description", value: "in the %1$@ section", comment: "Text explaining what section an article as a living document event change occurred in, if occurred in only one section. %1$@ is replaced with the section name.")

    static let twoSectionsDescription = WMFLocalizedString("aaald-two-sections-description", value: "in the %1$@ and %2$@ sections", comment: "Text explaining what sections an article as a living document event change occurred in, if occurred in two sections. %1$@ is replaced with the first section name, %2$@ with the second.")

    static let manySectionsDescription = WMFLocalizedString("aaald-many-sections-description", value: "in %1$d sections", comment: "Text explaining what sections an article as a living document change occurred in, if occurred in 3+ sections. %1$d is replaced with the number of sections.")

    static let newBookReferenceTitle = WMFLocalizedString("aaald-new-book-reference-title",
    value:"Book", comment: "Header text for a new book reference type that was added in an article as a living document cell.")

    static let newJournalReferenceTitle = WMFLocalizedString("aaald-new-journal-reference-title",
                                                             value:"Journal", comment: "Header text for a new journal reference type that was added in an article as a living document cell.")

    static let newNewsReferenceTitle = WMFLocalizedString("aaald-new-news-reference-title",
                                                          value:"News", comment: "Header text for a new news reference type that was added in an article as a living document cell.")

    static let newWebsiteReferenceTitle = WMFLocalizedString("aaald-new-website-reference-title",
                                                             value:"Website", comment: "Header text for a new website reference type that was added in an article as an living document cell.")

    static let newJournalReferenceVolume = WMFLocalizedString("aaald-new-journal-reference-volume",
    value:"Volume %1$@:", comment: "Volume text for a new journal reference type that was added in an article as a living document cell. %1$@ is replaced by the journal volume number of the reference.")

    static let newJournalReferenceDatabase = WMFLocalizedString("aaald-new-journal-reference-database",
    value:"via %1$@", comment: "Database text for a new journal reference type that was added in an article as a living document cell. %1$@ is replaced by the database volume number of the reference.")

    static let newWebsiteReferenceArchiveUrlText =  WMFLocalizedString("aaald-new-website-reference-archive-url-text",
    value:"Archive.org URL", comment: "Archive.org URL text for a new website reference type that was added in an article as a living document cell. This will be turned into a link that goes to the reference's Archive.org URL.")

    static let newWebsiteReferenceArchiveDateText = WMFLocalizedString("aaald-new-website-reference-archive-date-text",
    value:"from the original on %1$@", comment: "Text in a new website reference in an article as a living document cell that describes when the reference was retrieved for Archive.org. %1$@ is replaced with the reference's archive date.")

    static let newNewsReferenceRetrievedDate = WMFLocalizedString("aaald-new-news-reference-retrieved-date",
    value:"Retrieved %1$@", comment: "Retrieved date text for a new news reference type that was added in an article as a living document cell. %1$@ is replaced by the reference's retrieved date.")

    //tonitodo: this fails with EXC_BADACCESS when I try to use plural edits
    static let revisionUserInfo = WMFLocalizedString(
    "aaald-revision-userInfo",
    value:"Edit by %1$@ (%2$@ edits)", comment: "Text describing details about the user that made a significant revision in the article as a living document view. %1$@ is replaced by the editor name and %2$d is replaced by the number of edits they have made.")

    static let revisionUserInfoAnonymous = WMFLocalizedString("aaald-revision-by-anonymous",
    value:"Edit by anonymous user", comment: "Text describing the anonymous user that made a significant revision in the article as a living document view.")

    static let articleAsLivingDocSummaryTitle = WMFLocalizedString(
        "aaald-summary-title",
        value:"{{PLURAL:%1$d|0=0 changes|%1$d change|%1$d changes}} by {{PLURAL:%2$d|0=0 editors|%2$d editor|%2$d editors}} in {{PLURAL:%3$d|0=0 days|%3$d day|%3$d days}}",
        comment:"Describes how many small changes are batched together in the article as a living document timeline view. %1$d is replaced by the number of accumulated changes editors made, %2$d is replaced by the number of editors that made that change and %3$d is replaced with relative timeframe date that the edit counting started (e.g. 10 days).")

    @objc public static func onThisDayAdditionalEventsMessage(with languageCode: String?, locale: Locale, eventsCount: Int) -> String {
        return String(format: WMFLocalizedString("on-this-day-detail-header-title", languageCode: languageCode, value:"{{PLURAL:%1$d|%1$d historical event|%1$d historical events}}", comment:"Title for 'On this day' detail view - %1$d is replaced with the number of historical events which occurred on the given day"), locale: locale, eventsCount)
    }
    @objc public static func onThisDayHeaderDateRangeMessage(with languageCode: String?, locale: Locale, lastEvent: String, firstEvent: String) -> String {
        return String(format: WMFLocalizedString("on-this-day-detail-header-date-range", languageCode: languageCode, value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the oldest event year - i.e. '300 BC', %2$@ is replaced with string version of the most recent event year - i.e. '2006', "), locale: locale, lastEvent, firstEvent)
    }
    public static func onThisDayFooterWith(with eventCount: Int, languageCode: String? = nil, locale: Locale = Locale.autoupdatingCurrent) -> String {
        return String(format: WMFLocalizedString("on-this-day-footer-showing-event-count", languageCode: languageCode, value: "{{PLURAL:%1$d|%1$d more historical event|%1$d more historical events}} on this day", comment: "Footer for presenting user option to see longer list of 'On this day' articles. %1$@ will be substituted with the number of events"), locale: locale, eventCount)
    }
    public static let articleAsLivingDocErrorTitle = WMFLocalizedString("aaald-error-title", value: "Unable to load inline article history", comment: "Title of error banner that appears at the bottom of an article when significant events fail to load.")

    public static let articleAsLivingDocErrorSubtitle = WMFLocalizedString("aaald-error-subitle", value: "Refresh to try again", comment: "Subtitle of error banner that appears at the bottom of an article when significant events fail to load.")
}

// Language variant strings
public extension CommonStrings {

	// General

	static let variantsAlertPreferencesButton = WMFLocalizedString("variants-alert-preferences-button", value: "Review your preferences", comment: "Action button on alert used to inform users about variant support.")

	static let variantsAlertDismissButton = WMFLocalizedString("variants-alert-dismiss-button", value: "No thanks", comment: "Dismiss button on alert used to inform users about variant support.")

	// Chinese (zh)

	static let chineseVariantsAlertTitle = WMFLocalizedString("chinese-variants-alert-title", value: "Updates to Chinese variant support", comment: "Title of alert used to inform users about Chinese variant support.")

	static let chineseVariantsAlertBody = WMFLocalizedString("chinese-variants-alert-body", value: "The Wikipedia app now supports the following Chinese variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\n简体 Chinese, Simplified (zh-hans)\n香港繁體 Hong Kong Traditional (zh-hk)\n澳門繁體 Macau Traditional (zh-mo)\n大马简体 Malaysia Simplified (zh-my)\n新加坡简体 Singapore Simplified (zh-sg)\n臺灣正體 Taiwanese Traditional (zh-tw)", comment: "Body text of alert used to inform users about Chinese variant support. Please do not translate the newlines (\n) or Chinese characters (简体, 繁體, etc.).")

	// Crimean Tatar (crh)

	static let crimeanTatarVariantsAlertTitle =  WMFLocalizedString("crimean-tatar-variants-alert-title", value: "Updates to Crimean Tatar variant support", comment: "Title of alert used to inform users about Crimean Tatar variant support.")

	static let crimeanTatarVariantsAlertBody = WMFLocalizedString("crimean-tatar-variants-alert-body", value: "The Wikipedia app now supports the following Crimean Tatar variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nQırımtatarca, Latin Crimean Tatar Latin (chr-latn)\nкъырымтатарджа, Кирил Crimean Tatar Cyrillic (crh-cyrl)", comment: "Body text of alert used to inform users about Crimean Tatar variant support. Please do not translate the newlines (\n) or Crimean Tatar characters (къырымтатарджа, etc.).")

	// Gan (gan)

	static let ganVariantsAlertTitle =  WMFLocalizedString("gan-variants-alert-title", value: "Updates to Gan variant support", comment: "Title of alert used to inform users about Gan variant support.")

	static let ganVariantsAlertBody = WMFLocalizedString("gan-variants-alert-body", value: "The Wikipedia app now supports the following Gan variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\n贛語 原文 Gan (gan)\n赣语 简体 Gan, Simplified (gan-hans)\n贛語 繁體 Gan, Traditional (gan-hant)", comment: "Body text of alert used to inform users about Gan variant support. Please do not translate the newlines (\n) or Gan characters (贛語 原文, etc.).")

	// Inuktitut (iu)

	static let inuktitutVariantsAlertTitle =  WMFLocalizedString("inuktitut-variants-alert-title", value: "Updates to Inuktitut variant support", comment: "Title of alert used to inform users about Inuktitut variant support.")

	static let inuktitutVariantsAlertBody = WMFLocalizedString("inuktitut-variants-alert-body", value: "The Wikipedia app now supports the following Inuktitut variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nᐃᓄᒃᑎᑐᑦ ᑎᑎᕋᐅᓯᖅ ᓄᑖᖅ Inuktitut, Syllabics (ike-cans)\nInuktitut ilisautik, Inuktitut, Latin (ike-latn)", comment: "Body text of alert used to inform users about Inuktitut variant support. Please do not translate the newlines (\n) or Inuktitut characters (ᐃᓄᒃᑎᑐᑦ ᑎᑎᕋᐅᓯᖅ ᓄᑖᖅ, etc.).")

	// Kazakh (kk)

	static let kazakhVariantsAlertTitle =  WMFLocalizedString("kazakh-variants-alert-title", value: "Updates to Kazakh variant support", comment: "Title of alert used to inform users about Kazakh variant support.")

	static let kazakhVariantsAlertBody = WMFLocalizedString("kazakh-variants-alert-body", value: "The Wikipedia app now supports the following Kazakh variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nҚазақша Kazakh (kk)\nҚазақша Кирил Kazakh, Cyrillic (kk-cyrl)\nqazaqşa latin Kazakh, Latin (kk-latn)\nتوتە قازاقشا Kazakh, Arabic (kk-arab)", comment: "Body text of alert used to inform users about Kazakh variant support. Please do not translate the newlines (\n) or Kazakh characters (Қазақша, etc.).")

	// Kurdish (ku)

	static let kurdishVariantsAlertTitle =  WMFLocalizedString("kurdish-variants-alert-title", value: "Updates to Kurdish variant support", comment: "Title of alert used to inform users about Kurdish variant support.")

	static let kurdishVariantsAlertBody = WMFLocalizedString("kurdish-variants-alert-body", value: "The Wikipedia app now supports the following Kurdish variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nKurdî Latînî Kurdish, Latin (ku-latn)\nكوردی Kurdish, Arabic (kk-arab)", comment: "Body text of alert used to inform users about Kurdish variant support. Please do not translate the newlines (\n) or Kurdish characters (كوردی, etc.).")

	// Serbian (sr)

	static let serbianVariantsAlertTitle =  WMFLocalizedString("serbian-variants-alert-title", value: "Updates to Serbian variant support", comment: "Title of alert used to inform users about Serbian variant support.")

	static let serbianVariantsAlertBody = WMFLocalizedString("serbian-variants-alert-body", value: "The Wikipedia app now supports the following Serbian variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nсрпски ћирилица Serbian, Cyrillic (sr-ec)\nsrpski latinica Serbian, Latin (sr-el)", comment: "Body text of alert used to inform users about Serbian variant support. Please do not translate the newlines (\n) or Serbian characters (nсрпски ћирилица, etc.).")

	// Tajik (tg)

	static let tajikVariantsAlertTitle =  WMFLocalizedString("tajik-variants-alert-title", value: "Updates to Tajik variant support", comment: "Title of alert used to inform users about Tajik variant support.")

	static let tajikVariantsAlertBody = WMFLocalizedString("tajik-variants-alert-body", value: "The Wikipedia app now supports the following Tajik variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nтоҷикӣ кирилликӣ Tajik, Cyrillic (tg-cyrl)\ntojikī lotinī Tajik, Latin (tg-latn)", comment: "Body text of alert used to inform users about Tajik variant support. Please do not translate the newlines (\n) or Tajik characters (тоҷикӣ кирилликӣ, etc.).")

	// Uzbek (uz)

	static let uzbekVariantsAlertTitle =  WMFLocalizedString("uzbek-variants-alert-title", value: "Updates to Uzbek variant support", comment: "Title of alert used to inform users about Uzbek variant support.")

	static let uzbekVariantsAlertBody = WMFLocalizedString("uzbek-variants-alert-body", value: "The Wikipedia app now supports the following Uzbek variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\noʻzbekcha lotin Uzbek, Latin (uz-latin)\nўзбекча кирилл Uzbek, Cyrillic (uz-cyrl)", comment: "Body text of alert used to inform users about Uzbek variant support. Please do not translate the newlines (\n) or Uzbek characters (ўзбекча кирилл, etc.).")

	// Tachelhit

	static let tachelhitVariantsAlertTitle =  WMFLocalizedString("tachelhit-variants-alert-title", value: "Updates to Tachelhit variant support", comment: "Title of alert used to inform users about Tachelhit variant support.")

	static let tachelhitVariantsAlertBody = WMFLocalizedString("tachelhit-variants-alert-body", value: "The Wikipedia app now supports the following Tachelhit variants as primary or secondary languages within the app, making it easier to read, search and edit in your preferred variants:\n\nⵜⴰⵛⵍⵃⵉⵜ Tachelhit, Tifinagh (shi-tfng)\nTaclḥit Tachelhit, Latin (shi-latn)", comment: "Body text of alert used to inform users about Tachelhit variant support. Please do not translate the newlines (\n) or Tachelhit characters (ⵜⴰⵛⵍⵃⵉⵜ, etc.).")

}
