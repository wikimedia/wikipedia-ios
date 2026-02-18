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
    
    @objc public static func onLangWikipedia(with languageCode: String? = nil) -> String {
        
        var languageText: String?
        
        if languageCode == "test" {
            languageText = "Test"
        } else if languageCode == "test 2" {
            languageText = "Text 2"
        }
        
        if languageText == nil {
            if let languageCode {
                languageText = Locale.current.localizedString(forLanguageCode: languageCode)
            }
        }
        
        if let languageText {
            let format = WMFLocalizedString("explore-most-read-sub-heading-on-language-wikipedia", value: "On %1$@ Wikipedia", comment: "Subtext beneath the 'Most read articles' header when describing which specific Wikipedia. %1$@ will be replaced with the language - for example, 'On English Wikipedia'")
            return String.localizedStringWithFormat(format, languageText)
        } else {
            return WMFLocalizedString("explore-most-read-sub-heading-on-wikipedia", value: "On Wikipedia", comment: "Subtext beneath the 'Most read articles' header when the specific language wikipedia is unknown.")
        }
        
    }

    @objc public static let articleCountFormat = WMFLocalizedString("places-filter-top-articles-count", value:"{{PLURAL:%1$d|%1$d article|%1$d articles}}", comment: "Describes how many top articles are found in the top articles filter - %1$d is replaced with the number of articles")
    @objc public static let readingListCountFormat = WMFLocalizedString("reading-lists-count", value:"{{PLURAL:%1$d|%1$d reading list|%1$d reading lists}}", comment: "Describes the number of reading lists - %1$d is replaced with the number of reading lists")

    @objc public static let shortSavedTitle = WMFLocalizedString("action-saved", value: "Saved", comment: "Short title for the save button in the 'Saved' state - Indicates the article is saved. Please use the shortest translation possible. {{Identical|Saved}}")
    @objc public static let accessibilitySavedTitle = WMFLocalizedString("action-saved-accessibility", value: "Saved. Activate to unsave.", comment: "Accessibility title for the 'Unsave' action {{Identical|Saved}}")
    @objc public static let shortUnsaveTitle = WMFLocalizedString("action-unsave", value: "Unsave", comment: "Short title for the 'Unsave' action. Please use the shortest translation possible. {{Identical|Saved}}")

    @objc public static let accessibilityBackTitle = WMFLocalizedString("back-button-accessibility-label", value: "Back", comment: "Accessibility label for a button to navigate back. {{Identical|Back}}")

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
    @objc public static let savedTitle: String = CommonStrings.savedTitle(languageCode: nil)
    @objc public static let saveTitle: String = CommonStrings.saveTitle(languageCode: nil)
    @objc public static let unsaveTitle: String = WMFLocalizedString("button-saved-remove", value: "Remove from saved", comment: "Remove from saved button text used in various places.")
    @objc public static let dimImagesTitle = WMFLocalizedString("dim-images", value: "Dim images", comment: "Label for image dimming setting")

    @objc public static let searchTitle = WMFLocalizedString("search-title", value: "Search", comment: "Title for search interface. {{Identical|Search}}")
    @objc public static let settingsTitle = WMFLocalizedString("settings-title", value: "Settings", comment: "Title of the view where app settings are displayed. {{Identical|Settings}}")
    @objc public static let placesTabTitle = WMFLocalizedString("places-title", value: "Places", comment: "Title of the Places screen shown on the places tab.")
    @objc public static let historyTabTitle = WMFLocalizedString("history-title", value: "History", comment: "Title of the history screen shown on history tab {{Identical|History}}")
    @objc public static let exploreTabTitle = WMFLocalizedString("home-title", value: "Explore", comment: "Title for home interface. {{Identical|Explore}}")
    @objc public static let tabsTitle = WMFLocalizedString("tabs-title", value: "Tabs", comment: "Title for tabs")
    @objc public static let savedTabTitle = WMFLocalizedString("saved-title", value: "Saved", comment: "Title of the saved screen shown on the saved tab {{Identical|Saved}}")

    public static let wikimediaProjectsHeader = WMFLocalizedString("notifications-center-inbox-wikimedia-projects-section-title", value: "Wikimedia Projects", comment: "Title of the \"Wikimedia Projects\" section on filter adjustment views. This section allows the user to filter out other (non-Wikipedia) Wikimedia projects from displaying in their lists.")
    
    public static let wikimediaProjectsFooter = WMFLocalizedString("notifications-center-inbox-wikimedia-projects-section-footer", value: "Only projects you have created an account for will appear here", comment: "Footer of the \"Wikimedia Projects\" section on filter adjustment views. This section only lists projects that user has an account at.")
    
    public static let wikipediasHeader = WMFLocalizedString("notifications-center-inbox-wikipedias-section-title", value: "Wikipedias", comment: "Title of the \"Wikipedias\" section on filter adjustment views. This section allows the user to remove certain Wikipedia language projects from displaying in their lists.")
    
    @objc public static let notificationsCenterTitle = WMFLocalizedString("notifications-center-title", value: "Notifications", comment: "Title for Notifications Center interface, as well as the accessibility label for the button that navigates to Notifications Center.")
    @objc public static let notificationsCenterBadgeTitle = WMFLocalizedString("notifications-center-badge-button-accessibility-label", value: "Notifications with unread badge", comment: "Accessibility label for a button that navigates to Notifications Center. This button has a badge indicating there are unread notifications.")
    
    @objc public static let profileButtonTitle = WMFLocalizedString("profile-button-accessibility-label", value: "Profile", comment: "Accessibility label for the profile navigation bar button. Tapping it navigates to the user profile view.")
    @objc public static let profileButtonAccessibilityHint = WMFLocalizedString("profile-button-accessibility-hint", value: "Navigates to the profile view.", comment: "Accessibility hint for the profile navigation bar button. Explains to the user what will happen upon button tap.")
    @objc public static let profileButtonBadgeTitle = WMFLocalizedString("profile-button-badge-accessibility-label", value: "Profile with unread badge", comment: "Accessibility label for the profile navigation bar badge button. This button has a badge indicating there are unread notifications. Tapping it navigates to the user profile view.")
    
    public static let notificationsCenterMarkAsRead = WMFLocalizedString("notifications-center-mark-as-read", value: "Mark as Read", comment: "Button text in Notifications Center to mark a notification as read.")
    public static let notificationsCenterMarkAsReadSwipe = WMFLocalizedString("notifications-center-swipe-mark-as-read", value: "Mark as read", comment: "Button text in Notifications Center swipe actions to mark a notification as read.")
    public static let notificationsCenterMarkAsUnread = WMFLocalizedString("notifications-center-mark-as-unread", value: "Mark as Unread", comment: "Button text in Notifications Center to mark a notification as unread.")
    public static let notificationsCenterMarkAsUnreadSwipe = WMFLocalizedString("notifications-center-swipe-mark-as-unread", value: "Mark as unread", comment: "Button text in Notifications Center swipe actions to mark a notification as unread.")
    public static let notificationsCenterAllNotificationsStatus = WMFLocalizedString("notifications-center-status-all", value: "All", comment: "Text to indicate all notifications in Notifications Center.")
    public static let notificationsCenterReadNotificationsStatus = WMFLocalizedString("notifications-center-status-read", value: "Read", comment: "Text to indicate a read notification in Notifications Center.")
    public static let notificationsCenterUnreadNotificationsStatus = WMFLocalizedString("notifications-center-status-unread", value: "Unread", comment: "Text to indicate an unread notification in Notifications Center.")
    public static let notificationsCenterAgentDescriptionFromFormat = WMFLocalizedString("notifications-center-agent-description-from-format", value: "From %1$@", comment: "Text indicating who triggered a notification in notifications center. %1$@ will be replaced with the origin agent of the notification, which could be a username.")
    public static let notificationsCenterAlert = WMFLocalizedString("notifications-center-alert", value: "Alert", comment: "Description of various \"alert\" notification types, used on the notifications cell and detail views.")
    public static let notificationsCenterNotice = WMFLocalizedString("notifications-center-type-item-description-notice", value: "Notice", comment: "Description of \"notice\" notification types, used on the notification cell and detail views.")
    public static let notificationsChangePassword = WMFLocalizedString("notifications-center-change-password", value: "Change password", comment: "Button text in Notifications Center that routes user to change password screen.")
    public static let notificationsCenterDestinationWeb = WMFLocalizedString("notifications-center-destination-web", value: "On web", comment: "Informational text next to each notification center action on the detail screen, informing the user that the action will take them to a web view or outside of the app.")
    public static let notificationsCenterDestinationApp = WMFLocalizedString("notifications-center-destination-app", value: "In app", comment: "Informational text next to each notification center action on the detail screen, informing the user that the action will take them to a native view within the app.")
    public static let notificationsCenterLoginSuccessDescription = WMFLocalizedString("notifications-center-subheader-login-success-unknown-device", value: "Login from an unfamiliar device", comment: "Subtitle text for 'Successful login from an unknown device' notifications in Notifications Center and filters.")
    public static let notificationsCenterUserTalkPageMessage = WMFLocalizedString("notifications-center-type-title-user-talk-page-messsage", value: "Talk page message", comment: "Title of \"user talk page message\" notification type. Used on filters view toggles and the notification detail view.")
        public static let notificationsCenterPageReviewed =  WMFLocalizedString("notifications-center-type-title-page-review", value: "Page review", comment: "Title of \"page review\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterPageLinked =
         WMFLocalizedString("notifications-center-type-title-page-link", value: "Page link", comment: "Title of \"page link\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterConnectionWithWikidata = WMFLocalizedString("notifications-center-type-title-connection-with-wikidata", value: "Connection with Wikidata", comment: "Title of \"connection with Wikidata\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterEmailFromOtherUser = WMFLocalizedString("notifications-center-type-title-email-from-other-user", value: "Email from other user", comment: "Title of \"email from other user\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterMentionInTalkPage = WMFLocalizedString("notifications-center-type-title-talk-page-mention", value: "Talk page mention", comment: "Title of \"talk page mention\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterMentionInEditSummary =  WMFLocalizedString("notifications-center-type-title-edit-summary-mention", value: "Edit summary mention", comment: "Title of \"edit summary mention\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterSuccessfulMention =  WMFLocalizedString("notifications-center-type-title-sent-mention-success", value: "Sent mention success", comment: "Title of \"sent mention success\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterFailedMention = WMFLocalizedString("notifications-center-type-title-sent-mention-failure", value: "Sent mention failure", comment: "Title of \"sent mention failure\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterUserRightsChange = WMFLocalizedString("notifications-center-type-title-user-rights-change", value: "User rights change", comment: "Title of \"user rights change\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterEditReverted = WMFLocalizedString("notifications-center-type-title-edit-reverted", value: "Edit reverted", comment: "Title of \"edit reverted\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterLoginAttempts =  WMFLocalizedString("notifications-center-type-title-login-attempts", value: "Login attempts", comment: "Title of \"Login attempts\" notification type. Used on filters view toggles and the notification detail view. Represents failed logins from both a known and unknown device.")
    public static let notificationsCenterLoginSuccess = WMFLocalizedString("notifications-center-type-title-login-success", value: "Login success", comment: "Title of \"login success\" notification type. Used on filters view toggles and the notification detail view. Represents successful logins from an unknown device.")
    public static let notificationsCenterEditMilestone =  WMFLocalizedString("notifications-center-type-title-edit-milestone", value: "Edit milestone", comment: "Title of \"edit milestone\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterTranslationMilestone =  WMFLocalizedString("notifications-center-type-title-translation-milestone", value: "Translation milestone", comment: "Title of \"translation milestone\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterThanks = WMFLocalizedString("notifications-center-type-title-thanks", value: "Thanks", comment: "Title of \"thanks\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterWelcome = WMFLocalizedString("notifications-center-type-title-welcome", value: "Welcome", comment: "Title of \"welcome\" notification type. Used on filters view toggles and the notification detail view.")
    public static let notificationsCenterOtherFilter = WMFLocalizedString("notifications-center-type-title-other", value: "Other", comment: "Title of \"other\" notifications filter. Used on filter toggles.")

    @objc public static let exploreFeedTitle = WMFLocalizedString("welcome-exploration-explore-feed-title", value:"Explore feed", comment:"Title for Explore feed")
    @objc public static let featuredArticleTitle = WMFLocalizedString("explore-featured-article-heading", value: "Featured article", comment: "Text for 'Featured article' header")
    @objc public static let onThisDayTitle = CommonStrings.onThisDayTitle()
    @objc public static func onThisDayTitle(with languageCode: String? = nil) -> String {
        WMFLocalizedString("on-this-day-title", languageCode: languageCode, value: "On this day", comment: "Title for the 'On this day' feed section")
    }

    @objc public static let fromWikipedia = WMFLocalizedStringWithDefaultValue("explore-featured-article-sub-heading-from-language-wikipedia", nil, nil, "From %1$@ Wikipedia", "Subtext beneath the 'Featured article' header when describing which specific Wikipedia. %1$@ will be replaced with the language - for example, 'From English Wikipedia'")

    @objc public static let defaultFromWikipedia = WMFLocalizedStringWithDefaultValue("explore-featured-article-sub-heading-from-wikipedia", nil, nil, "From Wikipedia", "Subtext beneath the 'Featured article' header when the specific language wikipedia is unknown.")
    @objc public static let topReadTitle = WMFLocalizedString("places-filter-top-articles", value:"Top read", comment: "Title of places search filter that searches top articles")
    @objc public static let pictureOfTheDayTitle = WMFLocalizedString("explore-potd-heading", value: "Picture of the day", comment: "Text for 'Picture of the day' header")
    @objc public static let randomizerTitle = WMFLocalizedString("explore-randomizer", value: "Randomizer", comment: "Displayed on a button that loads another random article - it's a 'Randomizer'")
    @objc public static let languagesTitle = WMFLocalizedString("languages-settings-title", value: "Languages", comment: "Title for the 'Languages' section in Settings")
    @objc public static let relatedPagesTitle = WMFLocalizedString("explore-because-you-read", value: "Because you read", comment: "Text for 'Because you read' header")
    @objc public static let continueReadingTitle = WMFLocalizedString("explore-continue-reading-heading", value: "Continue reading", comment: "Text for 'Continue Reading' header")
    @objc public static let defaultText = WMFLocalizedString("insert-media-image-size-setting-default", value: "Default", comment: "Title for image size setting that sizes image using default size")
    
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

    @objc public static let textSizeSliderAccessibilityLabel = WMFLocalizedString("reading-themes-controls-accessibility-text-size-slider", value: "Text size slider", comment: "Accessibility label for the text size slider that adjusts text size.")

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
    public static let editArticleWarning = WMFLocalizedString("description-article-introduction-warning-message", value: "The ordering of elements will be different in the editing view than article view.", comment: "Description of alert dialouge to show ordering is different")
    @objc public static let updateActionTitle = WMFLocalizedString("action-update", value: "Update", comment: "Title of the update action.")
    @objc public static let cancelActionTitle = WMFLocalizedString("action-cancel", value: "Cancel", comment: "Title of the cancel action.")
    @objc public static let retryActionTitle = WMFLocalizedString("action-retry", value: "Retry", comment: "Title of the retry action.")
    
    // Survey strings
    public static let surveyTitle = WMFLocalizedString("survey-title", value: "Reason", comment: "Title of the survey view. Displayed in the navigation bar as title of view.")
    public static let surveySubmitActionTitle = WMFLocalizedString("survey-submit", value: "Submit", comment: "Title of the submit button. Displayed in survey views to submit answers.")
    public static let surveyInstructions = WMFLocalizedString("survey-instructions", value: "Select one or more options", comment: "Instructions displayed on survey views.")
    public static let surveyOtherPlaceholder = WMFLocalizedString("survey-other-placeholder", value: "Other", comment: "Title of other textfield placeholder option in survey view.")
    
    // TODO: Delete this when we remove web editor code
    @objc public static let discardEditsActionTitle = WMFLocalizedString("action-discard-edits", value: "Discard edits", comment: "Title of the discard edits action.")
    
    @objc public static let discardEditActionTitle = WMFLocalizedString("action-discard-edit", value: "Discard Edit", comment: "Title of the discard edit action button.")
    @objc public static let keepEditingActionTitle = WMFLocalizedString("action-keep-editing", value: "Keep Editing", comment: "Title of the keep editing action button.")

    @objc public static let sortActionTitle = WMFLocalizedString("action-sort", value: "Sort", comment: "Title of the sort action.")

    @objc public static let sortAlertTitle = WMFLocalizedString("reading-lists-sort-saved-articles", value: "Sort saved articles", comment: "Title of the alert that allows sorting saved articles.")
    public static let sortAlertOptionByTitle = WMFLocalizedString("sort-by-title-action", value: "Title", comment: "Title of the sort action that allows sorting items by title.")
    public static let sortAlertOptionByRecentlyAdded = WMFLocalizedString("sort-by-recently-added-action", value: "Recently added", comment: "Title of the sort action that allows sorting items by date added.")

    @objc public static let nextTitle = WMFLocalizedString("button-next", value: "Next", comment: "Button text for next button used in various places. {{Identical|Next}}")
    @objc public static let skipTitle = WMFLocalizedString("button-skip", value: "Skip", comment: "Button text for skip button used in various places.")
    @objc public static let okTitle = WMFLocalizedString("button-ok", value: "OK", comment: "Button text for ok button used in various places {{Identical|OK}}")
    @objc public static let userTitle = WMFLocalizedString("user-title", value: "User", comment: "Text that refers to a user in the app")
    
    public static let readingListsErrorListLimitExceeded = WMFLocalizedString("reading-lists-article-not-synced-list-limit-exceeded", value: "List limit exceeded, unable to sync article", comment: "Text of the alert label informing the user that article couldn't be synced.")
    public static let readingListsErrorArticleLimitExceeded = WMFLocalizedString("reading-lists-article-not-synced-article-limit-exceeded", value: "Article limit exceeded, unable to sync article", comment: "Text of the alert label informing the user that article couldn't be synced.")
    public static let readingListsErrorNotSynced = WMFLocalizedString("reading-lists-article-not-synced", value: "Not synced", comment: "Text of the alert label informing the user that article couldn't be synced.")
    public static let readingListsWarningArticleQueuedToBeDownloaded = WMFLocalizedString("reading-lists-article-queued-to-be-downloaded", value: "Article queued to be downloaded", comment: "Text of the alert label informing the user that article is queued to be downloaded.")

    @objc public static let doneTitle = WMFLocalizedString("description-published-button-title", value: "Done", comment: "Title for done button.")
    public static let goBackTitle = WMFLocalizedString("button-go-back", value: "Go back", comment: "Button text for Go back button used in various places")
    public static let publishAnywayTitle = WMFLocalizedString("button-publish-anyway", value: "Publish anyway", comment: "Button text for publish button used when first warned against publishing.")

    @objc public static let editNotices = WMFLocalizedString("edit-notices", value: "Edit notices", comment: "Title text and accessibility label for edit notices button.")
    @objc public static let undo = WMFLocalizedString("action-undo", value: "Undo", comment: "Title text and accessibility label for undo action on buttons or info sheets.")
    @objc public static let redo = WMFLocalizedString("action-redo", value: "Redo", comment: "Title text and accessibility label for redo action on buttons or info sheets.")
    @objc public static let findInPage = WMFLocalizedString("action-find-in-page", value: "Find in page", comment: "Title text and accessibility label for find in page action on buttons or info sheets.")
    @objc public static let readingThemesControls = WMFLocalizedString("article-toolbar-reading-themes-controls-toolbar-item", value: "Reading Themes Controls", comment: "Accessibility label for the Reading Themes Controls article toolbar item")

    public static let welcomePromiseTitle = WMFLocalizedString("description-welcome-promise-title", value:"By starting, I promise not to misuse this feature", comment:"Title text asking user to edit descriptions responsibly")
    @objc public static let gotItButtonTitle = WMFLocalizedString("welcome-explore-tell-me-more-done-button", value: "Got it", comment:"Text for button dismissing detailed explanation of new features")
    public static let getStartedTitle = WMFLocalizedString("welcome-explore-continue-button", value:"Get started", comment:"Text for button for dismissing welcome screens {{Identical|Get started}}")

    @objc public static let privacyPolicyTitle = WMFLocalizedString("privacy-policy-title", value: "Privacy policy", comment: "Title for the privacy Policy")
    @objc public static let termsOfUseTitle = WMFLocalizedString("terms-of-use-title", value: "Terms of use", comment: "Title for the terms of use")

    @objc public static let privacyPolicyURLString = "https://foundation.wikimedia.org/wiki/Policy:Privacy_policy"
    @objc public static let termsOfUseURLString = "https://foundation.wikimedia.org/wiki/Policy:Terms_of_Use"

    @objc public static let account = WMFLocalizedString("settings-account", value: "Account", comment: "Title for button and page letting user view their account page.")
    @objc public static let logIn = WMFLocalizedString("main-menu-account-login", value: "Log in", comment: "Button text for logging in.")

    @objc public static let myLanguages = WMFLocalizedString("settings-my-languages", value: "My languages", comment: "Title for list of user's preferred languages")
    @objc public static let readingPreferences = WMFLocalizedString("settings-appearance", value: "App theme", comment: "Title of the app theme screen.")
    @objc public static let pushNotifications = WMFLocalizedString("settings-notifications", value: "Push notifications", comment: "Title for view and button letting users change their push notifications settings.")

    public static let tryAgain = WMFLocalizedString("settings-notifications-echo-failure-try-again", value: "Try again", comment: "Text alerting the user to try action again after error")

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
    
    @objc public static let onGenericTitle = WMFLocalizedString("settings-on", value: "On", comment: "Text indicating a value is on in app Settings.")
    @objc public static let offGenericTitle = WMFLocalizedString("settings-off", value: "Off", comment: "Text indicating a value is off in app Settings.")
    
    @objc public static let allArticlesEmptySavedTitle = WMFLocalizedString("empty-no-saved-pages-title", value: "No saved pages yet", comment: "Title of a blank screen shown when a user has no saved pages")
    @objc public static let allArticlesEmptySavedSubtitle = WMFLocalizedString("empty-no-saved-pages-message", value: "Save pages to view them later, even offline", comment: "Message of a blank screen shown when a user has no saved pages")

    
    @objc public static let turnOnExploreTabTitle = WMFLocalizedString("explore-feed-preferences-turn-on-explore-tab-title", value: "Turn on the Explore tab?", comment: "Title for alert that allows users to turn on the Explore tab")
    @objc public static let turnOnExploreActionTitle = WMFLocalizedString("explore-feed-preferences-turn-on-explore-tab-action-title", value: "Turn on Explore", comment: "Title for action that allows users to turn on the Explore tab")
    @objc public static let customizeExploreFeedTitle = WMFLocalizedString("explore-feed-preferences-customize-explore-feed-action-title", value: "Customize Explore feed", comment: "Title for action that allows users to go to the Explore feed settings screen")
    public static let customize = WMFLocalizedString("customize-action-title", value: "Customize", comment: "Title for action that allows users to customize their preferences.")

    @objc public static let revertedEditTitle = WMFLocalizedString("reverted-edit-title", value: "Reverted edit", comment: "Title for notification informing user that their edit was reverted.")

    @objc public static let noInternetConnection = WMFLocalizedString("no-internet-connection", value: "No internet connection", comment: "String used in various places to indicate no internet connection")
    
    public static let unexpectedErrorAlertTitle = WMFLocalizedString("talk-page-error-alert-title", value: "Unexpected error", comment: "Title for unexpected error alert")
    
    @objc public static let noEmailClient = WMFLocalizedString("no-email-account-alert", value: "Please setup an email account on your device and try again.", comment: "Displayed to the user when they try to send a feedback email, but they have never set up an account on their device")
    
    @objc public static let vanishAccount = WMFLocalizedString("account-request-vanishing", value: "Vanish account", comment: "This will initiate the process of requesting your account to be vanished ")
    @objc public static var usernameFieldTitle = WMFLocalizedString("vanish-account-username-field", value: "Username and user page", comment: "Title for the username and userpage form field")

    // REMINDER: do not delete the app store strings below. We're not using them anywhere within the app itself but we need them to remain so they get upstreamed into TWN. ("localizations.swift copies the non-EN translations of these strings into respective Fastlane "Localized Metadata" files. See: https://docs.fastlane.tools/actions/deliver/)
    @objc public static let appStoreSubtitle = WMFLocalizedString("app-store-subtitle", value: "The free encyclopedia", comment: "Subtitle describing the app for the app store")
    @objc public static let appStoreShortDescription = WMFLocalizedString("app-store-short-description", value: "Download the Wikipedia app to explore places near you, sync articles to read offline and customize your reading experience.", comment: "Short description of the app for the app store")
    @objc public static let appStoreReleaseNotes = WMFLocalizedString("app-store-release-notes", value: "Fully customizable and easier to read Explore feed. Localization, performance improvements and bug fixes.", comment: "Short summary of what is new in this version of the app for the app store")
    @objc public static let appStoreKeywords = WMFLocalizedString("app-store-keywords", value: "Wikipedia, reference, wiki, encyclopedia, info, knowledge, research, information, explore, learn", comment: "Short list of keywords describing the app for the app store. It is required that these are individual words, not phrases, and are comma separated.")

    @objc public static let editAttribution = WMFLocalizedString("wikitext-upload-save-anonymously-warning", value: "Edits will be attributed to the IP address of your device. If you %1$@ you will have more privacy.", comment: "Button sub-text informing user or draw-backs of not signing in before saving wikitext. Parameters:\n* %1$@ - sign in button text")

    public static let genericErrorDescription = WMFLocalizedString("fetcher-error-generic", value: "Something went wrong. Please try again later.", comment: "Error shown to the user for generic errors with no clear recovery steps for the user.")

    public static let insertMediaTitle = WMFLocalizedString("insert-media-title", value: "Insert media", comment: "Title for the view in charge of inserting media into an article")

    public static let publishTitle = WMFLocalizedString("button-publish", value: "Publish", comment: "Button text for publish button used in various places. Please prioritize for de, ar and zh wikis. {{Identical|Publish}}")
    public static let logoutTitle = WMFLocalizedString("main-menu-account-logout", value: "Log out", comment: "Button text for logging out.")

    public static let insertLinkTitle = WMFLocalizedString("insert-link-title", value: "Insert link", comment: "Title for the Insert link screen")
    public static let editLinkTitle = WMFLocalizedString("edit-link-title", value: "Edit link", comment: "Title for the Edit link screen")

    public static let readStatusAccessibilityLabel = WMFLocalizedString("talk-page-discussion-read-accessibility-label", value: "Read", comment: "Accessibility text for indicating that some content have been read.")
    
    public static let unreadStatusAccessibilityLabel = WMFLocalizedString("talk-page-discussion-unread-accessibility-label", value: "Unread", comment: "Accessibility text for indicating that some content have not been read.")
    
    public static let talkPageNewBannerTitle = WMFLocalizedString("talk-page-new-banner-title", value: "Please be kind", comment: "Title text on banner that appears once user posts a new reply or discussion topic on their talk page.")

    public static let talkPageNewBannerSubtitle = WMFLocalizedString("talk-page-new-banner-subtitle", value: "Remember, we are all humans here", comment: "Subtitle text on banner that appears once user posts a new reply or discussion topic on their talk page.")

    public static func talkPageTitleUserTalk(languageCode: String?) -> String {
        WMFLocalizedString("talk-page-title-user-talk", languageCode: languageCode, value: "User Talk", comment: "This title label is displayed at the top of a talk page topic list, if the talk page type is a user talk page. Please prioritize for de, ar and zh wikis.")
    }

    public static func talkPageTitleArticleTalk(languageCode: String?) -> String {
        WMFLocalizedString("talk-page-title-article-talk", languageCode: languageCode, value: "Article Talk", comment: "This title label is displayed at the top of a talk page topic list, if the talk page type is an article talk page. Please prioritize for de, ar and zh wikis.")
    }

    public static let clearTitle = WMFLocalizedString("search-clear-title", value: "Clear", comment: "Text of the button shown to clear recent search terms")


    public static let clearRecentSearchesDialogTitle = WMFLocalizedString("search-recent-clear-confirmation-heading", value: "Delete all recent searches?", comment: "Heading text of delete all confirmation dialog")

    public static let clearRecentSearchesDialogSubtitle = WMFLocalizedString("search-recent-clear-confirmation-sub-heading", value: "This action cannot be undone!", comment: "Sub-heading text of delete all confirmation dialog")

    public static let deleteAllTitle = WMFLocalizedString("search-recent-clear-delete-all", value: "Delete All", comment: "Button text for confirming delete all action {{Identical|Delete all}}")

    public static let accessibilityClearTitle = WMFLocalizedString("clear-title-accessibility-label", value: "Clear", comment: "Accessibility label title for action that clears text")

    public static let recentlySearchedTitle = WMFLocalizedString("search-recent-title", value: "Recently searched", comment: "Title for list of recent search terms")

    public static let recentlySearchedEmpty = WMFLocalizedString("search-recent-empty", value: "No recent searches yet", comment: "String for no recent searches available")

    public static let successfullyPublishedDiscussion = WMFLocalizedString("talk-page-new-topic-success-text", value: "Your discussion was successfully published", comment: "Banner text that appears after a new discussion was successfully published on a talk page.")

    public static let successfullyPublishedReply = WMFLocalizedString("talk-page-new-reply-success-text", value: "Your reply was successfully published", comment: "Banner text that appears after a new reply was successfully published on a talk page discussion.")

    public static func talkPageReply(languageCode: String?) -> String {
        WMFLocalizedString("talk-page-reply-button", languageCode: languageCode, value: "Reply", comment: "Text used on button to reply to talk page messages.  Please prioritize for de, ar and zh wikis.")
    }
    @objc public static let talkPageReplyAccessibilityText = WMFLocalizedString("talk-page-reply-button-accessibility-label", value: "Reply to %@", comment: "Accessibility text for reply button. The %@ will be replaced with the name of the user whose comment is being responded")

    public static let revisionHistory = WMFLocalizedString("talk-page-revision-history", value: "Revision history", comment: "Title for menu option that leads to page revision history.")
    
    public static let articleRevisionHistory = WMFLocalizedString("article-revision-history", value: "Article revision history", comment: "Title for menu option that leads to article revision history.")

    public static let defaultThemeDisplayName = WMFLocalizedString("theme-default-display-name", value: "Default", comment: "Default theme name presented to the user")

    public static let moreButton = WMFLocalizedString("more-menu", value: "More", comment: "Accessibility title for more button in toolbar.")

    public static let watchlist = WMFLocalizedString("watchlist", value: "Watchlist", comment: "Title for watchlist feature.")
    
    public static let talkPage = WMFLocalizedString("account-talk-page-title", value: "Talk page", comment: "Link to talk page")

    public static let watchlistFilter = WMFLocalizedString("watchlist-filter", value: "Filter", comment: "Title for filter button in watchlist.")
    
    public static let watch = WMFLocalizedString("watch", value: "Watch", comment: "Title for watch toolbar button.")
    
    public static let unwatch = WMFLocalizedString("unwatch", value: "Unwatch", comment: "Title for unwatch toolbar button.")

    public static let rollback = WMFLocalizedString("diff-rollback", value: "Rollback", comment: "Title for rollback toolbar button.")
    
    public static let articleTalkPage = WMFLocalizedString("article-talk-page", value: "Article talk page", comment: "Title for article talk page button")

    public static let userButtonPage = WMFLocalizedString("watchlist-user-button-user-page", value: "User page", comment: "Title shown for user page action in user menu button in diff and watchlist views.")

    public static let userButtonTalkPage = WMFLocalizedString("watchlist-user-button-user-talk-page", value: "User talk page", comment: "Title shown for user talk page action in user menu button in diff and watchlist views.")

    public static let userButtonContributions = WMFLocalizedString("watchlist-user-button-user-contributions", value: "User contributions", comment: "Title shown for user contributions action in user menu button in diff and watchlist views.")

    public static let userButtonThank = WMFLocalizedString("watchlist-user-button-thank", value: "Thank", comment: "Title shown for thank action in user menu button in watchlist view.")

    public static let thanksMessage = WMFLocalizedString("diff-thanks-sent", value: "Your 'Thanks' was sent to %1$@", comment: "Message indicating thanks was sent. Parameters:\n* %1$@ - name of user who was thanked")

    public static let editSummaryTitle =  WMFLocalizedString("watchlist-edit-summary-accessibility", value: "Edit summary", comment: "Text for edit summary acessibility text")

    public static let filterOptionsAll = WMFLocalizedString("filter-options-all", value:  "All", comment: "Common option on filter adjustment views to allow All types in the associated section.")
    public static let userMenuButtonAccesibilityText = WMFLocalizedString("diff-user-button-accessibility-text", value: "Double tap to open menu", comment: "Accessibility text to provide more context to users of assistive tecnologies about the user button actions")

    public static let watchlistFilterLatestRevisionsHeader =  WMFLocalizedString("watchlist-filter-latest-revisions-header", value:  "Latest Revisions", comment: "Header of watchlist filter adjustment view \"Latest Revisions\" section.")
    
    public static let watchlistFilterLatestRevisionsOptionLatestRevision = WMFLocalizedString("watchlist-filter-latest-revisions-options-latest-revision", value:  "Latest revision", comment: "Option in the watchlist filter adjustment view \"Latest Revisions\" section. When selected, this option only displays the latest revision of a page in the user's watchlist.")
    
    public static let watchlistFilterLatestRevisionsOptionNotTheLatestRevision = WMFLocalizedString("watchlist-filter-latest-revisions-options-not-latest-revision", value: "Not the latest revision", comment: "Option in the watchlist filter adjustment view \"Latest Revisions\" section. When selected, this option displays multiple revisions of the same page in the user's watchlist.")
    
    public static let watchlistFilterActivityHeader = WMFLocalizedString("watchlist-filter-activity-header", value:  "Watchlist Activity", comment: "Header of watchlist filter adjustment view \"Watchlist Activity\" section.")
    
    public static let watchlistFilterActivityOptionUnseenChanges = WMFLocalizedString("watchlist-filter-activity-options-unseen-changes", value: "Unseen changes", comment: "Option in the watchlist filter adjustment view \"Watchlist Activity\" section. When selected, this option only displays unseen revisions in the user's watchlist.")
    
    public static let watchlistFilterActivityOptionSeenChanges = WMFLocalizedString("watchlist-filter-activity-options-seen-changes", value: "Seen changes", comment: "Option in the watchlist filter adjustment view \"Watchlist Activity\" section. When selected, this option only displays seen revisions in the user's watchlist.")
    
    public static let watchlistFilterAutomatedContributionsHeader = WMFLocalizedString("watchlist-filter-automated-contributions-header", value:  "Automated Contributions", comment: "Header of watchlist filter adjustment view \"Automated Contributions\" section.")
    
    public static let watchlistFilterAutomatedContributionsOptionBot = WMFLocalizedString("watchlist-filter-automated-contributions-options-bot", value: "Bot", comment: "Option in the watchlist filter adjustment view \"Automated Contributions\" section. When selected, this option only displays edits made by bots in the user's watchlist.")
    
    public static let watchlistFilterAutomatedContributionsOptionHuman = WMFLocalizedString("watchlist-filter-automated-contributions-options-human", value: "Human (not bot)", comment: "Option in the watchlist filter adjustment view \"Automated Contributions\" section. When selected, this option only displays edits made by humans in the user's watchlist.")
    
    public static let watchlistFilterSignificanceHeader = WMFLocalizedString("watchlist-filter-significance-header", value:  "Significance", comment: "Header of watchlist filter adjustment view \"Significance\" section.")
    
    public static let watchlistFilterSignificanceOptionMinorEdits = WMFLocalizedString("watchlist-filter-significance-options-minor-edits", value: "Minor edits", comment: "Option in the watchlist filter adjustment view \"Significance\" section. When selected, this option only displays minor edits in the user's watchlist.")
    
    public static let watchlistFilterSignificanceOptionNonMinorEdits = WMFLocalizedString("watchlist-filter-significance-options-non-minor-edits", value: "Non-minor edits", comment: "Option in the watchlist filter adjustment view \"Significance\" section. When selected, this option only displays non-minor edits in the user's watchlist.")
    
    public static let watchlistFilterUserRegistrationHeader = WMFLocalizedString("watchlist-filter-user-registration-header", value:  "User registration and experience", comment: "Header of watchlist filter adjustment view \"User Registration and Experience\" section.")
    
    public static let watchlistFilterUserRegistrationOptionUnregistered = WMFLocalizedString("watchlist-filter-user-registration-options-unregistered", value: "Unregistered", comment: "Option in the watchlist filter adjustment view \"User Registration and Experience\" section. When selected, this option only displays unregistered/anonymous edits in the user's watchlist.")
    
    public static let watchlistFilterUserRegistrationOptionRegistered = WMFLocalizedString("watchlist-filter-user-registration-options-registered", value: "Registered", comment: "Option in the watchlist filter adjustment view \"User Registration and Experience\" section. When selected, this option only displays registered/non-anonymous edits in the user's watchlist.")
    
    public static let watchlistFilterTypeOfChangeHeader = WMFLocalizedString("watchlist-filter-type-of-change-header", value:  "Type of change", comment: "Header of watchlist filter adjustment view \"Type of Change\" section.")
    
    public static let watchlistFilterTypeOfChangeOptionPageEdits = WMFLocalizedString("watchlist-filter-type-of-change-options-page-edits", value: "Page edits", comment: "Option in the watchlist filter adjustment view \"Type of Change\" section. When selected, this option includes page edits in the user's watchlist.")
    public static let watchlistFilterTypeOfChangeOptionPageCreations = WMFLocalizedString("watchlist-filter-type-of-change-options-page-creations", value: "Page creations", comment: "Option in the watchlist filter adjustment view \"Type of Change\" section. When selected, this option includes page creations in the user's watchlist.")
    public static let watchlistFilterTypeOfChangeOptionCategoryChanges = WMFLocalizedString("watchlist-filter-type-of-change-options-category-changes", value: "Category changes", comment: "Option in the watchlist filter adjustment view \"Type of Change\" section. When selected, this option includes category changes in the user's watchlist.")
    public static let watchlistFilterTypeOfChangeOptionWikidataEdits = WMFLocalizedString("watchlist-filter-type-of-change-options-wikidata-edits", value: "Wikidata edits", comment: "Option in the watchlist filter adjustment view \"Type of Change\" section. When selected, this option includes wikidata edits in the user's watchlist.")
    public static let watchlistFilterTypeOfChangeOptionLoggedActions = WMFLocalizedString("watchlist-filter-type-of-change-options-logged-actions", value: "Logged actions", comment: "Option in the watchlist filter adjustment view \"Type of Change\" section. When selected, this option includes logged actions in the user's watchlist.")

    public static let watchlistFilterAddLanguageButtonTitle = WMFLocalizedString("watchlist-filters-add-language", value:"Add language...", comment: "Title for button in watchlist filter view to add additional languages to watchlist view.")

    public static let watchlistEmptyViewTitle = WMFLocalizedString("watchlist-empty-view-title", value: "Articles you added to the Watchlist appear here", comment: "Title for empty watchlist view")

    public static let watchlistEmptyViewSubtitle = WMFLocalizedString("watchlist-empty-view-subtitle", value: "Keep track of what's happening to articles you are interested in. Tap the menu in the article and select “Watch” to see changes to an article.", comment: "Subtitle for empty watchlist view")

    public static let watchlistEmptyViewButtonTitle = WMFLocalizedString("watchlist-empty-view-button-title", value: "Search articles", comment: "Title for empty watchlist view button that redirects user to search articles")

    public static let watchlistEmptyViewFilterTitle = WMFLocalizedString("watchlist-empty-view-filter-title", value: "You have no Watchlist items", comment: "Title for empty watchlist view when filters are active")

    public static let watchlistGoToDiff = WMFLocalizedString("watchlist-diff-action-button-title", value: "Go to diff", comment: "Title for watchlist menu button item for go to diff action")

    public static let diffFromHeading = WMFLocalizedString("diff-compare-header-from-info-heading", value: "Previous Edit", comment: "Heading label in info box for previous revision when comparing two revisions.")

    public static let diffToHeading = WMFLocalizedString("diff-compare-header-to-info-heading", value: "Displayed Edit", comment: "Heading label in info box for current revision when comparing two revisions.")

    public static let diffArticleEditHistory = WMFLocalizedString("diff-article-revision-history", value: "Article revision history", comment: "Label for article edit history menu item in diff more menu.")

    public static let diffSingleLineFormat = WMFLocalizedString("diff-single-line-format", value:"Line %1$d", comment:"Label in diff to indicate how many lines a change section encompases. This format is for a single change line. %1$d is replaced by the change line number.")

    public static let diffMultiLineFormat = WMFLocalizedString("diff-multi-line-format", value:"Lines %1$d - %2$d", comment:"Label in diff to indicate how many lines a change section encompases. This format is for multiple change lines. %1$d is replaced by the starting line number and %2$d is replaced by the ending line number.")
    
    public static let diffUndoSuccess = WMFLocalizedString("diff-undo-success", value:"The revision was undone.", comment:"Success message shown to user when they successfully undid an edit.")
    
    public static let diffRollbackSuccess = WMFLocalizedString("diff-rollback-success", value:"Edits reverted.", comment:"Success message shown to user when they successfully rolled back an edit.")

    public static let compareTitle = WMFLocalizedString("page-history-compare-title", value: "Compare", comment: "Title for action button that allows users to contrast different items")
    public static let maxRevisionsSelectedWarningTitle = WMFLocalizedString("page-history-revisions-comparison-warning", value: "Only two revisions can be selected", comment: "Text telling the user how many revisions can be selected for comparison")

    public static let loginOrCreateAccountTitle = WMFLocalizedString("reading-list-login-or-create-account-button-title", value:"Log in or create account", comment:"Title for button to login or create account.")

    @objc public static let diffErrorTitle = WMFLocalizedString("diff-revision-error-title", value: "Unable to load revision", comment: "Text for placeholder label visible when there has been an error while fetching the diff.")

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

    public static let watchlistOnboardingTitle = WMFLocalizedString("watchlist-onboarding-title", value: "Introducing your Watchlist", comment: "Watchlists onboarding modal title")

    public static let watchlistTrackChangesTitle = WMFLocalizedString("watchlist-track-title", value: "Track changes", comment: "Watchlists onboarding modal track changes section title")

    public static let watchlistTrackChangesSubtitle = WMFLocalizedString("watchlist-track-subtitle", value: "The Watchlist is a tool that lets you keep track of changes made to pages or articles you're interested in.", comment: "Watchlists onboarding modal track changes section subtitle")

    public static let watchlistWatchChangesTitle = WMFLocalizedString("watchlist-watch-title", value: "Watch articles", comment: "Watchlists onboarding modal watch articles section title")

    public static let watchlistWatchChangesSubitle = WMFLocalizedString("watchlist-watch-subtitle", value: "By tapping the star or \"Watch\" action in the bottom toolbar of an article, you can add that page to your Watchlist.", comment: "Watchlists onboarding modal watch articles section subtitle")

    public static let watchlistSetExpirationTitle = WMFLocalizedString("watchlist-expiration-title", value: "Set expiration", comment: "Watchlists onboarding modal set expiration section title")

    public static let watchlistSetExpirationSubtitle = WMFLocalizedString("watchlist-expiration-subtitle", value: "Pages remain by default, but options exist for temporary watching ranging from one week to one year.", comment: "Watchlists onboarding modal set expiration section subtitle")

    public static let watchlistViewUpdatesTitle = WMFLocalizedString("watchlist-updates-title", value: "View updates", comment: "Watchlists onboarding modal view updates section title")

    public static let watchlistViewUpdatesSubitle = WMFLocalizedString("watchlist-updates-subtitle", value: "The Watchlist of the pages you've added, like edits or discussions, can be accessed via Settings → Account.", comment: "Watchlists onboarding modal view updates section subtitle")

    public static let watchlistOnboardingLearnMore = WMFLocalizedString("watchlist-onboarding-button-title", value: "Learn more about the Watchlist", comment: "Watchlists onboarding modal learn more button title")

    public static let continueButton = WMFLocalizedString("continue-button-title", value: "Continue", comment: "Continue button title")

    public static let donateThankTitle = WMFLocalizedString("donate-success-title", value: "Thank you!", comment: "Thank you toast title displayed after a user successfully donates.")
    public static let donateThankSubtitle = WMFLocalizedString("donate-success-subtitle", value: "Your generosity means so much to us.", comment: "Thank you toast subtitle displayed after a user successfully donates.")

     @objc public static let donateTitle = WMFLocalizedString("settings-donate", value: "Donate", comment: "Link to donate")

    @objc public static func onThisDayAdditionalEventsMessage(with languageCode: String?, locale: Locale, eventsCount: Int) -> String {
        return String(format: WMFLocalizedString("on-this-day-detail-header-title", languageCode: languageCode, value:"{{PLURAL:%1$d|%1$d historical event|%1$d historical events}}", comment:"Title for 'On this day' detail view - %1$d is replaced with the number of historical events which occurred on the given day"), locale: locale, eventsCount)
    }
    @objc public static func onThisDayHeaderDateRangeMessage(with languageCode: String?, locale: Locale, lastEvent: String, firstEvent: String) -> String {
        return String(format: WMFLocalizedString("on-this-day-detail-header-date-range", languageCode: languageCode, value:"from %1$@ - %2$@", comment:"Text for 'On this day' detail view events 'year range' label - %1$@ is replaced with string version of the oldest event year - i.e. '300 BC', %2$@ is replaced with string version of the most recent event year - i.e. '2006', "), locale: locale, lastEvent, firstEvent)
    }
    public static func onThisDayFooterWith(with eventCount: Int, languageCode: String? = nil, locale: Locale = Locale.autoupdatingCurrent) -> String {
        return String(format: WMFLocalizedString("on-this-day-footer-showing-event-count", languageCode: languageCode, value: "{{PLURAL:%1$d|%1$d more historical event|%1$d more historical events}} on this day", comment: "Footer for presenting user option to see longer list of 'On this day' articles. %1$@ will be substituted with the number of events"), locale: locale, eventCount)
    }
    
    // TODO: Delete this when we remove web editor code
    public static let editorExitConfirmationTitle = WMFLocalizedString("editor-exit-confirmation-title", value: "Dismiss the editing mode?", comment: "Title text of editing mode confirmation alert. Presented to the user when they they are about to be navigated away from the editor flow.")
    public static let editorExitConfirmationBody =  WMFLocalizedString("editor-exit-confirmation-body", value: "Are you sure you want to leave editing mode without publishing first?", comment: "Body text of editing mode confirmation alert. Presented to the user when they they are about to be navigated away from the editor flow.")
    
    public static let editorExitConfirmationMessage =  WMFLocalizedString("editor-exit-confirmation-message", value: "Are you sure you want to discard this edit?", comment: "Message text of editing mode confirmation alert. Presented to the user when they they are about to be navigated away from the editor flow.")
    
    public static let talkPageCloseConfirmationKeepEditing = WMFLocalizedString("talk-pages-compose-close-confirmation-keep", value: "Keep Editing", comment: "Title of keep editing action, displayed within a confirmation alert to user when they attempt to close the new topic view or new reply after entering text. Please prioritize for de, ar and zh wikis.")
    
    public static let findReplaceHeader = WMFLocalizedString("find-replace-header", value: "Find and replace", comment: "Find and replace header title.")
    
    public static let emptyEditSummary = WMFLocalizedString("empty-edit-summary", value: "Empty edit summary", comment: "Label when looking at a particular article revision. Indicates that the user did not add a summary.")

    // Native page editor

    public static let editorKeyboardTextFormattingTitle = WMFLocalizedString("editor-keyboard-text-formatting-title", value: "Text Formatting", comment: "Title of text formatting keyboard view on the editor.")
    
    public static let editorKeyboardParagraphButton = WMFLocalizedString("editor-keyboard-paragraph-button", value: "Paragraph", comment: "Paragraph button label in the text formatting keyboard view on the editor.")
    public static let editorKeyboardHeadingButton = WMFLocalizedString("editor-keyboard-heading-button", value: "Heading", comment: "Heading button label in the text formatting keyboard view on the editor.")
    public static let editorKeyboardSubheading1Button = WMFLocalizedString("editor-keyboard-subheading1-button", value: "Subheading 1", comment: "Subheading1 button label in the text formatting keyboard view on the editor.")
    public static let editorKeyboardSubheading2Button = WMFLocalizedString("editor-keyboard-subheading2-button", value: "Subheading 2", comment: "Subheading2 button label in the text formatting keyboard view on the editor.")
    public static let editorKeyboardSubheading3Button = WMFLocalizedString("editor-keyboard-subheading3-button", value: "Subheading 3", comment: "Subheading3 button label in the text formatting keyboard view on the editor.")
    public static let editorKeyboardSubheading4Button = WMFLocalizedString("editor-keyboard-subheading4-button", value: "Subheading 4", comment: "Subheading4 button label in the text formatting keyboard view on the editor.")
    
    public static let editorReplaceTypeSingle = WMFLocalizedString("editor-replace-type-single", value: "Replace", comment: "Label indicating which replace type the user has set in the find and replace view on the editor. This type replaces a single instance of the find text.")
    public static let editorReplaceTypeAll = WMFLocalizedString("editor-replace-type-all", value: "Replace all", comment: "Label indicating which replace type the user has set in the find and replace view on the editor. This type replaces all instances of the find text.")
    public static let editorReplaceTextfieldPlaceholder = WMFLocalizedString("editor-replace-textfield-placeholder", value: "Replace with...", comment: "Placeholder label displayed when the replace textfield in the editor's find and replace view is empty.")
    
    public static let editorFailToScrollToArticleSelectedTextTitle = WMFLocalizedString("edit-menu-item-could-not-find-selection-alert-title", value:"The text that you selected could not be located", comment:"Title for alert informing user their text selection could not be located in the article wikitext.")
    public static let editorFailToScrollToArticleSelectedTextBody = WMFLocalizedString("edit-menu-item-could-not-find-selection-alert-message", value:"This might be because the text you selected is not editable (eg. article title or infobox titles) or the because of the length of the text that was highlighted", comment:"Description of possible reasons the user text selection could not be located in the article wikitext.")
    
    public static let editorToolbarButtonOpenTextFormatMenuAccessiblityLabel = WMFLocalizedString("editor-toolbar-open-text-format-menu-accessibility", value: "Open text formatting menu", comment: "Accessibility label for text format toolbar button on the editor. This button opens the keyboard text formatting menu.")
    
    public static let editorToolbarButtonReferenceAccessiblityLabel = WMFLocalizedString("editor-toolbar-reference-accessibility", value: "Reference text formatting", comment: "Accessibility label for reference toolbar button on the editor.")
    public static let editorKeyboardButtonReferenceAccessiblityLabel = WMFLocalizedString("editor-keyboard-reference-accessibility", value: "Reference", comment: "Accessibility label for reference keyboard button on the editor.")
    
    public static let editorToolbarButtonLinkAccessiblityLabel = WMFLocalizedString("editor-toolbar-link-accessibility", value: "Link text formatting", comment: "Accessibility label for link toolbar button on the editor.")
    public static let editorKeyboardButtonLinkAccessiblityLabel = WMFLocalizedString("editor-keyboard-link-accessibility", value: "Link", comment: "Accessibility label for link keyboard button on the editor.")
    
    public static let editorToolbarButtonTemplateAccessiblityLabel = WMFLocalizedString("editor-toolbar-template-accessibility", value: "Template text formatting", comment: "Accessibility label for template toolbar button on the editor.")
    public static let editorKeyboardButtonTemplateAccessiblityLabel = WMFLocalizedString("editor-keyboard-template-accessibility", value: "Template", comment: "Accessibility label for template keyboard button on the editor.")

    public static let editorToolbarButtonImageAccessiblityLabel = WMFLocalizedString("editor-toolbar-image-accessibility", value: "Image text formatting", comment: "Accessibility label for image toolbar button on the editor.")

    public static let editorToolbarButtonFindAccessiblityLabel = WMFLocalizedString("editor-toolbar-find-accessibility", value: "Find in page", comment: "Accessibility label for find toolbar button on the editor. This button opens the find in page view.")
    
    public static let editorToolbarShowMoreOptionsButtonAccessiblityLabel = WMFLocalizedString("editor-toolbar-show-more-accessibility", value: "Show more formatting options", comment: "Accessibility label for expand button on the formatting toolbar in editor. This button reveals more formatting toolbar buttons.")
    
    public static let editorToolbarButtonListUnorderedAccessiblityLabel = WMFLocalizedString("editor-toolbar-list-unordered-accessibility", value: "Unordered list text formatting", comment: "Accessibility label for unordered list toolbar button on the editor.")
    public static let editorKeyboardButtonListUnorderedAccessiblityLabel = WMFLocalizedString("editor-keyboard-list-unordered-accessibility", value: "Unordered list", comment: "Accessibility label for unordered list keyboard button on the editor.")
    
    public static let editorToolbarButtonListOrderedAccessiblityLabel = WMFLocalizedString("editor-toolbar-list-ordered-accessibility", value: "Ordered list text formatting", comment: "Accessibility label for ordered list toolbar button on the editor.")
    public static let editorKeyboardButtonListOrderedAccessiblityLabel = WMFLocalizedString("editor-keyboard-list-ordered-accessibility", value: "Ordered list", comment: "Accessibility label for ordered list keyboard button on the editor.")
    
    public static let editorToolbarButtonIndentIncreaseAccessiblityLabel = WMFLocalizedString("editor-toolbar-indent-increase-accessibility", value: "Increase indent text formatting", comment: "Accessibility label for increase indent toolbar button on the editor.")
    public static let editorKeyboardButtonIndentIncreaseAccessiblityLabel = WMFLocalizedString("editor-keyboard-indent-increase-accessibility", value: "Increase indent", comment: "Accessibility label for increase indent keyboard button on the editor.")
    
    public static let editorToolbarButtonIndentDecreaseAccessiblityLabel = WMFLocalizedString("editor-toolbar-indent-decrease-accessibility", value: "Decrease indent text formatting", comment: "Accessibility label for decrease indent toolbar button on the editor.")
    public static let editorKeyboardButtonIndentDecreaseAccessiblityLabel = WMFLocalizedString("editor-keyboard-indent-decrease-accessibility", value: "Decrease indent", comment: "Accessibility label for decrease indent keyboard button on the editor.")
    
    public static let editorToolbarButtonCursorUpAccessiblityLabel = WMFLocalizedString("editor-toolbar-cursor-up-accessibility", value: "Move cursor up to previous line.", comment: "Accessibility label for move cursor up button on the editor. This button moves the cursor up to the previous line.")
    public static let editorToolbarButtonCursorDownAccessiblityLabel = WMFLocalizedString("editor-toolbar-cursor-down-accessibility", value: "Move cursor down to next line.", comment: "Accessibility label for move cursor down button on the editor. This button moves the cursor down to the next line.")
    public static let editorToolbarButtonCursorPreviousAccessiblityLabel = WMFLocalizedString("editor-toolbar-cursor-previous-accessibility", value: "Move cursor to previous character.", comment: "Accessibility label for move cursor down button on the editor. This button moves the cursor to the previous character.")
    public static let editorToolbarButtonCursorNextAccessiblityLabel = WMFLocalizedString("editor-toolbar-cursor-next-accessibility", value: "Move cursor to next character.", comment: "Accessibility label for move cursor next button on the editor. This button moves the cursor to the next character.")
    
    public static let editorToolbarButtonBoldAccessiblityLabel = WMFLocalizedString("editor-toolbar-bold-accessibility", value: "Bold text formatting", comment: "Accessibility label for bold toolbar button on the editor.")
    public static let editorKeyboardButtonBoldAccessiblityLabel = WMFLocalizedString("editor-keyboard-bold-accessibility", value: "Bold", comment: "Accessibility label for bold keyboard button on the editor.")

    public static let editorToolbarButtonItalicsAccessiblityLabel = WMFLocalizedString("editor-toolbar-italics-accessibility", value: "Italics text formatting", comment: "Accessibility label for italics toolbar button on the editor.")
    public static let editorKeyboardButtonItalicsAccessiblityLabel = WMFLocalizedString("editor-keyboard-italics-accessibility", value: "Italics", comment: "Accessibility label for italics keyboard button on the editor.")
 
    public static let editorKeyboardButtonCommentAccessiblityLabel = WMFLocalizedString("editor-keyboard-comment-accessibility", value: "Comment", comment: "Accessibility label for comment keyboard button on the editor.")
    
    public static let editorKeyboardButtonSuperscriptAccessiblityLabel = WMFLocalizedString("editor-keyboard-superscript-accessibility", value: "Superscript", comment: "Accessibility label for superscript keyboard button on the editor.")
    
    public static let editorKeyboardButtonSubscriptAccessiblityLabel = WMFLocalizedString("editor-keyboard-subscript-accessibility", value: "Subscript", comment: "Accessibility label for subscript keyboard button on the editor.")
    
    public static let editorKeyboardButtonUnderlineAccessiblityLabel = WMFLocalizedString("editor-keyboard-underline-accessibility", value: "Underline", comment: "Accessibility label for underline keyboard button on the editor.")
    
    public static let editorKeyboardButtonStrikethroughAccessiblityLabel = WMFLocalizedString("editor-keyboard-strikethrough-accessibility", value: "Strikethrough", comment: "Accessibility label for strikethrough keyboard button on the editor.")
    
    public static let editorKeyboardButtonCloseTextFormatMenuAccessiblityLabel = WMFLocalizedString("editor-keyboard-close-text-format-menu-accessibility", value: "Close text formatting menu", comment: "Accessibility label for close keyboard button on the editor. This button closes the keyboard text formatting menu.")
    
    public static let editorWikitextTextViewAccessibility = WMFLocalizedString("editor-wikitext-textview-accessibility", value: "Wiki text editor", comment: "Accessibility label for the wikitext editor textview.")
    public static let editorWikitextLoadingAccessibility = WMFLocalizedString("editor-wikitext-loading-accessibility", value: "Loading editor text", comment: "Accessibility announcement when the editor textview is activated. This will be spoken with VoiceOver if loading takes a while.")
    public static let editorFindTextFieldAccessibilityLabel = WMFLocalizedString("editor-find-textfield-accessibility", value: "Find", comment: "Accessibility label for the find textfield on the editor")
    public static let editorFindClearButtonAccessibilityLabel = WMFLocalizedString("editor-find-clear-button-accessibility", value: "Clear find", comment: "Accessibility label for the clear find button on the editor. This button clears the text in the find textfield.")
    public static let editorFindCurrentMatchInfoFormatAccessibilityLabel = WMFLocalizedString("editor-find-current-match-info-accessibility", value: "%1$@ total matches found. Highlighted match number %2$@", comment: "Accessibility text for the match results informational label. %1$@ is replaced by the total number of matches found. %2$@ is replaced by which number match is currently highlighted.")
    public static let editorFindCurrentMatchInfoZeroResultsAccessibilityLabel = WMFLocalizedString("editor-find-current-match-info-zero-results-accessibility", value: "No matches found", comment: "Accessibility text for zero match results informational label.")
    public static let editorFindCloseButtonAccessibilityLabel = WMFLocalizedString("editor-find-close-button-accessibility", value: "Close find", comment: "Accessibility label for the close find button on the editor. This button clears out find results and closes the find in page view.")
    public static let editorFindNextButtonAccessibilityLabel = WMFLocalizedString("editor-find-next-button-accessibility", value: "Next find result", comment: "Accessibility label for the find next result on the editor. This button highlights the next find result in the editor text.")
    public static let editorFindPreviousButtonAccessibilityLabel = WMFLocalizedString("editor-find-previous-button-accessibility", value: "Previous find result", comment: "Accessibility label for the find previous result on the editor. This button highlights the previous find result in the editor text.")
    public static let editorReplaceTextFieldAccessibilityLabel = WMFLocalizedString("editor-replace-textfield-accessibility", value: "Replace", comment: "Accessibility label for the replace textfield on the editor")
    public static let editorReplaceClearButtonAccessibilityLabel = WMFLocalizedString("editor-replace-clear-button-accessibility", value: "Clear replace", comment: "Accessibility label for the clear replace button on the editor. This button clears the text in the replace textfield.")
    
    public static let editorReplaceButtonFormatAccessibilityLabel = WMFLocalizedString("editor-replace-button-format-accessibility", value: "Perform replace operation. Replace type is set to %1$@.", comment: "Accessibility label for the replace button on the editor. %1$@ is replaced by the replace type the user has set (single instance or all instances).")
    
    public static let editorReplaceTypeButtonFormatAccessibilityLabel = WMFLocalizedString("editor-replace-type-button-accessibility", value: "Switch replace type. Currently set to %1$@. Select to change.", comment: "Accessibility label for the replace type button on the editor. %1$@ is replaced by the replace type the user has set (single instance or all instances).")

    public static let editorReplaceTypeSingleAccessibility = WMFLocalizedString("editor-replace-type-single-accessibility", value: "Replace single instance", comment: "Accessibility text for the replace single instance type on the editor.")
    public static let editorReplaceTypeAllAccessibility = WMFLocalizedString("editor-replace-type-all-accessibility", value: "Replace all instances", comment: "Accessibility text for the replace all instances type on the editor.")
    
    public static let editContextMenuTitle = WMFLocalizedString("edit-menu-item", value: "Edit", comment: "Button label for 'Edit' context menu item")
    
    public static let editorTitle = WMFLocalizedString("editor-title", value: "Editor", comment: "Title of editor view.")
    
    public static let editSource = WMFLocalizedString("editor-edit-source", value: "Edit source", comment: "Title for menu option to edit the source of a page.")
    
    public static let editPublishedToastTitle = WMFLocalizedString("editor-edit-published", value: "Your edit was published.", comment: "Title for alert informing that the user's new edit was successfully published.")
    
    @objc public static let suggestedEditsTitle = WMFLocalizedString("suggested-edits-title", value: "Suggested Edits", comment: "Title for the 'Suggested Edits' explore feed card")
    
    public static func editSummaryShortDescriptionAdded(with languageCode: String? = nil) -> String {
        WMFLocalizedString(
            "edit-summary-short-description-added",
            languageCode: languageCode,
            value: "Added short description",
            comment: "Edit summary message when adding a short description for an article")
    }
    
    public static func editSummaryShortDescriptionUpdated(with languageCode: String? = nil) -> String {
        WMFLocalizedString(
            "edit-summary-short-description-updated",
            languageCode: languageCode,
            value: "Updated short description",
            comment: "Edit summary message when updating the short description of an article")
    }

    // Image recommendations

    public static let tryNowTitle = WMFLocalizedString("try-now-title", value: "Try now", comment: "Title of action button. Tapping takes user to a particular feature.")
    public static let addImageTitle = WMFLocalizedString("image-rec-title", value: "Add image", comment: "Title of the image recommendation view. Displayed in the navigation bar above an article summary.")
    public static let viewArticle = WMFLocalizedString("image-rec-view-article", value: "View article", comment: "Button from an image recommendation article summary. Tapping the button displays the full article.")
    public static let bottomSheetTitle =  WMFLocalizedString("image-rec-add-image-title", value: "Add this image?", comment: "title for the add image suggestion view")
    public static let noButtonTitle = WMFLocalizedString("image-recs-no-title", value: "No", comment: "Button title for discarding an image suggestion")
    public static let yesButtonTitle = WMFLocalizedString("image-recs-yes-title", value: "Yes", comment: "Button title for accepting an image suggestion")
    public static let notSureButtonTitle = WMFLocalizedString("image-recs-not-sure-title", value: "Not sure", comment: "Button title for skipping an image suggestion")
   
    public static func learnMoreTitle(languageCode: String? = nil) -> String {
        WMFLocalizedString("learn-more-title", languageCode: languageCode, value: "Learn more", comment: "Button title text to learn more, used in various contexts. It typically sends users to another view with additional context about the feature.")
    }
    
    public static let tutorialTitle = WMFLocalizedString("tutorial-title", value: "Tutorial", comment: "Button title text that triggers a tutorial flow. This can be a series of tooltips informing the user on how a feature works.")
    
    public static let problemWithFeatureTitle = WMFLocalizedString("problem-with-feature-title", value: "Problem with feature", comment: "Button title text that allows user to send feedback to the iOS support email about a particular feature.")

    public static let returnToArticle = WMFLocalizedString("return-to-article", value: "Return to article", comment: "Title for button indicating that is possible to go back to article")

    public static let returnButtonTitle = WMFLocalizedString("return-button-title", value: "Return", comment: "Title for button indicating that is possible return from this point")

    public static let feedbackSurveyToastTitle = WMFLocalizedString("alt-text-feedback-survey-toast-title", value: "Feedback submitted", comment: "Text for the toast displayed after a user answers a survey")

    // Accountˆ¨

    public static let logoutAlertTitle =  WMFLocalizedString("main-menu-account-logout-are-you-sure", value: "Are you sure you want to log out?", comment: "Header asking if user is sure they wish to log out.")

    public static let logoutAlertMessage = WMFLocalizedString("main-menu-account-logout-are-you-sure-message", value: "Logging out will delete your locally stored account data (notifications and messages), but your account data will still be available on the web and will be re-downloaded if you log back in.", comment: "Message explaining what happens to local data when logging out.")
    
    public static let yearInReviewLoginPromptProfileTitle = WMFLocalizedString("profile-year-in-review-login-title", value: "Log in for access to Year in Review", comment: "Title of alert that asks user to login if they are entering Year in Review.")
    public static let yearInReviewLoginPromptIntroTitle = WMFLocalizedString("year-in-review-intro-login-title", value: "Log in for personalization", comment: "Title of alert that asks user to login if they want to view the personalized feature.")
    public static let yearInReviewLoginPromptSubtitle = WMFLocalizedString("profile-year-in-review-login-subtitle", value: "Log in or create an account to see Year in Review and be eligible for more personalized insights.", comment: "Subtitle of alert that asks user to login. Displayed after they completed the feature for the first time.")
    
    public static let joinLoginTitle = WMFLocalizedString("profile-page-join-title", value: "Log in / Join Wikipedia", comment: "Link to sign up or sign in")
    
    public static let noThanksTitle = WMFLocalizedString("variants-alert-dismiss-button", value: "No thanks", comment: "Dismiss button on alert used to inform users about variant support.")
    public static let continueWithoutLoggingIn = WMFLocalizedString("ip-account-cta-bottom", value: "Continue without logging in", comment: "Continue without logging in button title")
    
    public static func takeSurveyTitle(languageCode: String?) -> String {
        WMFLocalizedString("import-shared-reading-list-survey-prompt-button-take-survey", languageCode: languageCode, value:"Take survey", comment:"Title of action button on import reading list survey prompt, which takes user to external survey.")
    }
    
    public static let notNowTitle = WMFLocalizedString("not-now-title", value: "Not now", comment: "Text for the dismiss button across various features.")
    
    public static let youCanAccessYIR = WMFLocalizedString("year-in-review-intro-exit-toast-title", value: "You can access your Year in Review later in Profile.", comment: "Toast displayed to user after the exit Year in Review on the intro slide.")

    public static let logoCaption = WMFLocalizedString("year-in-review-highlights-share-logo-caption", value: "Wikipedia logo", comment: "Caption for Wikipedia logo on sharable version of the highlights year in review slide")
    
    public static let todayTitle = WMFLocalizedString("today-title", value: "Today", comment: "Title for today section on article view history")
    
    public static let yesterdayTitle = WMFLocalizedString("yesterday-title", value: "Yesterday", comment: "Title for yesterday section on article view history")
    
    public static let readString = WMFLocalizedString("notifications-center-filters-read-status-item-title-read", value: "Read", comment: "Title of Read option in the read status section of the notifications center filter view. Selecting this only displays read notifications in the notifications center.")

    // Donation history

    @objc public static let deleteDonationHistory = WMFLocalizedString("donate-history-delete", value: "Delete local donation history", comment: "Text for delete locally saved donation history button")

    @objc public static let confirmDeletionTitle = WMFLocalizedString("confirm-donation-history-deletion-title", value: "Confirm deletion", comment: "Title for confirm local donation history deletion alert")

    @objc public static let confirmDeletionSubtitle = WMFLocalizedString("confirm-donation-history-deletion-subtitle", value: "This will only apply to donations made from this device.", comment: "Subtitle for confirm local donation history deletion alert")

    @objc public static let confirmedDeletion = WMFLocalizedString("confirmed-donation-history-deletion", value: "Local history deleted", comment: "Title for confirming deletion of locally saved donations alert")

    // Year In Review

    @objc public static let yirTitle = WMFLocalizedString("year-in-review-button-title", value: "Year in Review", comment: "Year in review title. Appears on buttons in the profile and settings menu.")
    
    public static let exploreYIRTitlePersonalized = WMFLocalizedString("year-in-review-feature-announcement-title-personalized", value: "Explore your Wikipedia Year in Review", comment: "Title for year in review feature announcement")
    public static let exploreYIRBodyPersonalized =  WMFLocalizedString("year-in-review-feature-explore-body-personalized-updated", value: "See insights about which articles you read on the Wikipedia app and the edits you made in 2024. Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.", comment: "Body for year in review feature announcement")
    
    public static let exploreYIRBodyV3 =  WMFLocalizedString("year-in-review-feature-explore-body-v3", value: "See insights about which articles you read on the Wikipedia app and the edits you made.", comment: "Body for year in review feature announcement - version 3")
    
    public static let exploreYIRFooterV3 =  WMFLocalizedString("year-in-review-feature-explore-footer-v3", value: "Your reading history is kept protected. Reading insights are calculated using locally stored data on your device.", comment: "Footer text in the year in review intro view.")

    public static let exploreYiRTitle = WMFLocalizedString("year-in-review-feature-announcement-title", value: "Explore Wikipedia in Review", comment: "Title for year in review feature announcement")
    public static let exploreYIRBody =  WMFLocalizedString("year-in-review-feature-explore-body", value: "Wikipedia is the largest knowledge resource ever assembled in the history of the world, and it’s freely available to everyone everywhere. Here’s a review of 2024 through the lens of Wikipedia. ", comment: "Body for year in review feature announcement")
    
    public static let yirFeatureAnnoucementBody =  WMFLocalizedString("year-in-review-feature-announcement-body", value: "See insights about what articles we read and edited, and share highlights from our year on Wikipedia.", comment: "Body for year in review feature announcement")
    public static let yirFeatureAnnoucementBodyPersonalized =  WMFLocalizedString("year-in-review-feature-announcement-body-personalized", value: "See insights about the articles you read on the Wikipedia app, share your journey, and discover highlights from your year.", comment: "Body for year in review feature announcement")
    
    public static let searchButtonAccessibilityLabel = WMFLocalizedString("search-button-accessibility-label", value: "Search Wikipedia", comment: "Accessibility label for a button that opens a search box to search Wikipedia.")

    @objc public static let emptyNoHistoryTitle = WMFLocalizedString("empty-no-history-title", value: "No history to show", comment: "Title of a blank screen shown when a user has no history")
    @objc public static let emptyNoHistorySubtitle = WMFLocalizedString("empty-no-history-message", value: "Keep track of what you've been reading here", comment: "Message of a blank screen shown when a user has no history")

    public static let searchBarPlaceholder = WMFLocalizedString("search-field-placeholder-text", value: "Search Wikipedia", comment: "Search field placeholder text")

    // Lockscreen Search Widget strings
    public static let lockscreenSearchWidgetDescription = WMFLocalizedString("lockscreen-search-widget-description", value: "Quick access to search Wikipedia from your lock screen.", comment: "Text for description of lockscreen search widget displayed when adding to lock screen.")
    
    // Temp accs
    public static let tempAccountsReadMoreTitle = WMFLocalizedString("temp-account-toast-read-more-title", value: "Read more", comment: "Read more button for the toast for temporary accounts.")
    
    public static let tempAccountsToastTitle = {
        let openingBold = "<b>"
        let closingBold = "</b>"
        let format = WMFLocalizedString("temp-account-toast-title", value: "%1$@You are currently using a temporary account.%2$@ Edits made with the temporary...",
          comment: "Temporary accounts toast information. $1 and $2 are opening and closing bold")
        return String.localizedStringWithFormat(format, openingBold, closingBold)
    }
    
    @objc public static let tempAccount = WMFLocalizedString("temporary-account", value: "Temporary Account", comment: "Temporary account title text")
    
    public static let ipWarningTitle = WMFLocalizedString("ip-account-warning-title", value: "You are not logged in", comment: "Warning title text presented to anonymous editors before entering an edit flow.")
    
    public static let tempWarningTitle = WMFLocalizedString("temp-account-warning-title", value: "You are using a temporary account", comment: "Warning title text presented to temporary account editors before entering an edit flow.")
    
    public static let ipWarningSubtitle = WMFLocalizedString("ip-account-warning-subtitle", value: "On publish a temporary account will be created for you.", comment: "Warning subtitle text presented to anonymous editors before entering an edit flow.")
    
    public static func tempWarningSubtitle(username: String) -> String {
        let format = WMFLocalizedString("temp-warning-subtitle-format", value: "Your edit will be attributed to %1$@", comment: "Warning subtitle text presented to temporary account editors before entering an edit flow. %1$@ is replaced with the temporary account username.")
        return String.localizedStringWithFormat(format, username)
    }
    
    public static let tempAccountCreatedToastTitle = WMFLocalizedString("article-view-controller-editing-temp-account-created-title", value: "Temporary account created", comment: "After a user edits an article, creating an IP account, this pop-up title lets them know.")
    
    public static func tempAccountCreatedToastSubtitle(username: String?) -> String {
        let format = WMFLocalizedString("article-view-controller-editing-temp-account-created-subtitle", value: "Temporary account %1$@ was created after your edit was published. It will expire in 90 days.", comment: "More information on the creation of temporary accounts, $1 replaces their username.")
        return String.localizedStringWithFormat(format, username ?? "*****")
    }
    public static let saveViewTempAccountNotice = WMFLocalizedString("save-view-temp-account-notice", value: "You are using a temporary account. Edits are being attributed to %1$@...", comment: "$1 is the temporary username for the temporary account notice.")
    public static let saveViewTempAccountWarning = WMFLocalizedString("save-view-temp-account-warning", value: "You are not logged in. Once you make an edit, a temporary account will be created for you to protect your privacy.", comment: "Warning that a temporary account will be created")
    public static let tempAccountPublishTitle = WMFLocalizedString("article-view-controller-editing-temp-account-created-title", value: "Temporary account created", comment: "After a user edits an article, creating an IP account, this pop-up title lets them know.")
    // MARK: - Activity tab strings
    public static let activityTabReadingHistory = WMFLocalizedString("activity-tab-read-title", value: "View reading history", comment: "Title for the reading history activity tab")

    @objc public static let activityTitle = WMFLocalizedString("activity-tab-title", value: "Activity", comment: "Activity title")
    public static let activityTabLoggedOutTitle = WMFLocalizedString("activity-tab-log-in-or-create-account", value: "Log in or create an account to see more editing and reading activity.", comment: "Title for activity tab when users are logged out.")
    public static let actitvityTabLoggedOutSubtitle = WMFLocalizedString("activity-tab-logged-out-track-what-youve-read", value: "Track what you’ve read and view your contributions over time in a new way", comment: "Subtitle for activity tab when users are logged out.")
    public static let activityTabViewReadingHistoryTitle = WMFLocalizedString("activity-tab-view-reading-history", value: "View reading history", comment: "Button title for users to view their reading history.")
    public static let activityTabViewSavedArticlesTitle = WMFLocalizedString("activity-tab-view-saved-articles", value: "View saved articles", comment: "Button title for users to view their saved articles.")
    public static let activityTabViewEditingTitle = WMFLocalizedString("activity-tab-view-editing-history", value: "View editing history", comment: "Button title for users to view their editing history.")
    
    public static let activityTabNoEditsAddImagesTitle = WMFLocalizedString("activity-tab-no-edits-title", value: "You haven't edited this week. Add images to enhance article understanding.", comment: "Title for users that have not made any edits.")
    
    public static let activityTabNoEditsGenericTitle = WMFLocalizedString("activity-tab-generic-no-edits", value: "You haven't edited this week. Start now to track your contributions.", comment: "Title for users that have not made any edits.")
    
    public static let activityTabStartEditing = WMFLocalizedString("activity-tab-start-editing", value: "Start editing", comment: "Button title for users to begin editing.")
    public static func activityTabArticleReadNumber(amount: Int? = 0) -> String {
        let format = WMFLocalizedString("activity-tab-you-read", value: "You read {{PLURAL:%1$d|%1$d article|%1$d articles}} this week.", comment: "Displays how many articles the user read in the past week, $1 is the amount, returning the pluralized version of article depending.")
        return String.localizedStringWithFormat(format, amount ?? 0)
    }
    public static func activityTabArticleSavedNumber(amount: Int? = 0) -> String {
        let format = WMFLocalizedString("activity-tab-you-saved", value: "You saved {{PLURAL:%1$d|%1$d article|%1$d articles}} this week.", comment: "Displays how many articles the user saved in the past week, $1 is the amount, returning the pluralized version of article depending.")
        return String.localizedStringWithFormat(format, amount ?? 0)
    }
    public static func activityTabArticleEditedNumber(amount: Int? = 0) -> String {
        let format = WMFLocalizedString("activity-tab-you-edited", value: "You edited {{PLURAL:%1$d|%1$d time|%1$d times}} this week.", comment: "Displays how many articles the user edited in the past week, $1 is the amount, returning the pluralized version of article depending.")
        return String.localizedStringWithFormat(format, amount ?? 0)
    }
    public static var activityTabAddImagesTitle = WMFLocalizedString("activity-tab-add-images-title", value: "Add images", comment: "Title for add images feature suggestion.")
    public static var activityTabAddImagesSubitle = WMFLocalizedString("activity-tab-add-images-subtitle", value: "Add suggested images to Wikipedia articles to enhance understanding.", comment: "Subtitle for add images feature.")
    public static var satisfactionSurveyTitle = WMFLocalizedString("activity-tab-survey-title", value: "Satisfaction survey", comment: "Satisfaction survey view title")
    public static var surveyVerySatisfied = WMFLocalizedString("activity-tab-very-satisfied", value: "Very satisfied", comment: "Satisfaction survey very satisfied")
    public static var surveySatisfied = WMFLocalizedString("activity-tab-satisfied", value: "Satisfied", comment: "Satisfaction survey satisfied")
    public static var surveyVeryUnsatisfied = WMFLocalizedString("activity-tab-very-unsatisfied", value: "Very unsatisfied", comment: "Satisfaction survey very unsatisfied")
    public static var surveyUnsatisfied = WMFLocalizedString("activity-tab-unsatisfied", value: "Unsatisfied", comment: "Satisfaction survey unsatisfied")
    public static var surveyNeutral = WMFLocalizedString("activity-tab-neutral", value: "Neutral", comment: "Satisfaction survey neutral")
    public static var surveyAdditionalThoughts = WMFLocalizedString("activity-tab-additional-thoughts", value: "Any additional thoughts?", comment: "Asking user if they have any comments")
    
    // MARK: - Article Tabs
    
    public static let articleTabsOpen = WMFLocalizedString("article-tabs-open", value: "Open", comment: "Menu option button for opening an article in the current tab. Displayed upon long press of an article link.")
    
    public static let articleTabsOpenInNewTab = WMFLocalizedString("article-tabs-open-new-tab", value: "Open in new tab", comment: "Menu option button for opening an article in a new tab. Displayed upon long press of an article link.")
    
    public static let articleTabsOpenInBackgroundTab = WMFLocalizedString("article-tabs-open-background-tab", value: "Open in background tab", comment: "Menu option button for opening an article in a background tab. Displayed upon long press of an article link.")
    
    public static let articleTabsLimitToastFormat = WMFLocalizedString("article-tabs-max-reached", value: "Tab limit reached (%1$d). The article was opened in the current tab. Please close one or more tabs.", comment: "Warning toast presented to users when they attempt to open a new tab after maximum tab number is reached. %1$d is replaced with the maximum number of tabs allowed.")
    
    public static let onboardingTooltipsForTabs = WMFLocalizedString("article-tabs-onboarding-tooltip", value: "Onboarding tooltips for tabs", comment: "Tooltip title for tabs onboarding.")
    public static let tabsNavigation = WMFLocalizedString("article-tabs-navigation", value: "Tabs navigation", comment: "Title for navigation in article tabs")

    public static func closeAllTabsConfirmation(count: Int? = 0) -> String {
        let format = WMFLocalizedString("close-all-tabs-confirmation", value: "Do you want to close all %1$@ tabs? This action can’t be undone.", comment: "Confirmation message for closing a variable number of tabs. $1 is the amount of tabs currently open.")
        return String.localizedStringWithFormat(format, count ?? 0)
    }

    public static func closeAllTabsConfirmationNumber(count: Int? = 0) -> String {
        let format = WMFLocalizedString("close-all-tabs-confirmation-number", value: "Close all %1$@ tabs?", comment: "Confirmation message closing a number of tabs. $1 is the amount of tabs to be closed")
        return String.localizedStringWithFormat(format, count ?? 0)
    }
    
    public static let saveAllTabs = WMFLocalizedString("save-all-tabs", value: "Save all tabs", comment: "Action to save all open tabs.")
    public static let closeAllTabs = WMFLocalizedString("close-all-tabs", value: "Close all tabs", comment: "Action to close all open tabs.")
    public static let duplicateTab = WMFLocalizedString("duplicate-tab", value: "Duplicate tab", comment: "Action to duplicate the current tab.")
    public static let closeOtherTabs = WMFLocalizedString("close-other-tabs", value: "Close other tabs", comment: "Action to close all tabs except the current one.")
    public static let newTab = WMFLocalizedString("new-tab", value: "New tab", comment: "Title for creating a new tab.")
    public static let closeTabConfirmation = WMFLocalizedString("close-tab-confirmation", value: "Close tab?", comment: "Confirmation prompt to close a single tab.")
    public static let closeTabs = WMFLocalizedString("close-tabs", value: "Close tabs", comment: "Action to confirm closing multiple tabs.")
    public static let savedAllTabs = WMFLocalizedString("saved-all-tabs", value: "Saved all tabs.", comment: "Message indicating all open tabs were saved.")
    public static let savedAllTabsViewReadingList = WMFLocalizedString("saved-all-tabs-view-reading-list", value: "Saved all tabs. View reading list.", comment: "Message indicating all tabs were saved with option to view reading list.")
    public static let mainPage = WMFLocalizedString("main-page", value: "Main page", comment: "Title for the Wikipedia main page.")
    
    public static let articleTabsFeatureAnnouncementTitle = WMFLocalizedString("article-tabs-feature-announcement-title", value: "Introducing Tabs", comment: "Title for the article tabs feature announcement")
    public static let articleTabsFeatureAnnouncementItem1Title = WMFLocalizedString("article-tabs-feature-announcement-item-1-title", value: "Browse with tabs", comment: "Title for the article tabs feature announcement item")
    public static let articleTabsFeatureAnnouncementItem1Subtitle = WMFLocalizedString("article-tabs-feature-announcement-item-1-subtitle", value: "Open multiple articles and switch between them with ease.", comment: "Subtitle for the article tabs feature announcement item 2")
    public static let articleTabsFeatureAnnouncementItem2Title = WMFLocalizedString("article-tabs-feature-announcement-item-2-title", value: "Pick up where you left off", comment: "Title for the article tabs feature announcement item 2")
    public static let articleTabsFeatureAnnouncementItem2Subtitle = WMFLocalizedString("article-tabs-feature-announcement-item-2-subtitle", value: "Tabs remember your scroll position automatically.", comment: "Subtitle for the article tabs feature announcement item 2")
    public static let articleTabsFeatureAnnouncementItem3Title = WMFLocalizedString("article-tabs-feature-announcement-item-3-title", value: "Save links for later", comment: "Title for the article tabs feature announcement item 3")
    public static let articleTabsFeatureAnnouncementItem3Subtitle = WMFLocalizedString("article-tabs-feature-announcement-item-3-subtitle", value: "Open links in background tabs without losing your place.", comment: "Subtitle for the article tabs feature announcement item 3")
    public static let articleTabsFeatureAnnouncementItem4Title = WMFLocalizedString("article-tabs-feature-announcement-item-4-title", value: "Personalize your new tab", comment: "Title for the article tabs feature announcement item 4")
    public static let articleTabsFeatureAnnouncementItem4Subtitle = WMFLocalizedString("article-tabs-feature-announcement-item-4-subtitle", value: "Choose fun facts or reading suggestions when opening a new tab.", comment: "Subtitle for the article tabs feature announcement item 4")
    public static let articleTabsFeatureAnnouncementSubCTA = WMFLocalizedString("article-tabs-feature-announcement-sub-cta", value: "Learn more about Tabs", comment: "Call to action text in the article tabs feature announcement, inviting the user to learn more about tabs.")

    public static let tabsButtonAccessibilityHint = WMFLocalizedString("article-tabs-button-accessibility-hint", value: "Navigates to tabs overview", comment: "Accessibility hint for the tabs navigation bar button")
    public static let tabsButtonAccessibilityLabel = WMFLocalizedString("article-tabs-button-accessibility-label", value: "Article tabs", comment: "Accessibility label for the tabs navigation bar button")
    public static let mainPageSubtitle = WMFLocalizedString("tabs-main-page-subtitle", value: "Wikipedia’s daily highlights", comment: "Main page subtitle")
    public static let mainPageDescription = WMFLocalizedString("tabs-main-page-description", value: "Discover featured articles, the latest news, interesting facts, and key stats on Wikipedia’s main page.", comment: "Main page description")
    public static let tabThumbnailSubtitle = WMFLocalizedString("tabs-thumbnail-subtitle", value: "Begin your search here", comment: "New tab thumbanail subtitle")
    public static let tabThumbanailDescription = WMFLocalizedString("tabs-thumbnail-description", value: "Explore Wikipedia, the free encyclopedia that anyone can edit", comment: "New tab thumbanail description")

    // Search Widget Feature Announcement

    @objc public static let searchWidgetAnnouncementTitle = WMFLocalizedString("search-widget-announcement-title", value: "New Search widget available", comment: "Title for the search widget feature announcement")
    
    @objc public static let searchWidgetAnnouncementBody = WMFLocalizedString("search-widget-announcement-body", value: "Add the Wikipedia Search widget to your Home or Lock Screen for faster answers, right at your fingertips.", comment: "Body text for the search widget feature announcement")
    
    public static let newTabTheme = WMFLocalizedString("settings-new-article-tab-header-text", value: "New Tab Theme", comment: "Header title for the New Article Tabs settings to determine between preferences")
}

// Language variant strings
public extension CommonStrings {

	// General

	static let variantsAlertPreferencesButton = WMFLocalizedString("variants-alert-preferences-button", value: "Review your preferences", comment: "Action button on alert used to inform users about variant support.")

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
