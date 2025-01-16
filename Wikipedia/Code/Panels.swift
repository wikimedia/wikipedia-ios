import WMFData
import WMFComponents

class AnnouncementPanelViewController : ScrollableEducationPanelViewController {

    enum Style {
        case standard
        case minimal
    }
    
    private let announcement: WMFAnnouncement
    private let style: Style

    init(announcement: WMFAnnouncement, style: Style = .standard, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme) {
        self.announcement = announcement
        self.style = style
        super.init(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
        isUrgent = announcement.announcementType == .fundraising
        self.footerLinkAction = footerLinkAction
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        subheadingHTML = announcement.text
        subheadingTextAlignment = style == .minimal ? .center : .natural
        primaryButtonTitle = announcement.actionTitle
        secondaryButtonTitle = announcement.negativeText
        footerHTML = announcement.captionHTML
        secondaryButtonTextStyle = .mediumFootnote
        spacing = 20
        buttonCornerRadius = 8
        buttonTopSpacing = 10
        primaryButtonTitleEdgeInsets = UIEdgeInsets(top: 14, left: 14, bottom: 14, right: 14)
        dismissWhenTappedOutside = true
        contentHorizontalPadding = 20
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        evaluateConstraintsOnNewSize(view.frame.size)
    }

    private func evaluateConstraintsOnNewSize(_ size: CGSize) {
        let panelWidth = size.width * 0.9
        if style == .minimal && traitCollection.horizontalSizeClass == .regular && traitCollection.verticalSizeClass == .regular {
            width = min(320, panelWidth)
        } else {
            width = panelWidth
        }
        
        if style == .minimal {
            // avoid scrolling on SE landscape, otherwise add a bit of padding
            let subheadingExtraTopBottomSpacing = size.height <= 320 ? 0 : CGFloat(10)
            subheadingTopConstraint.constant = originalSubheadingTopConstraint + CGFloat(subheadingExtraTopBottomSpacing)
            subheadingBottomConstraint.constant = originalSubheadingTopConstraint + CGFloat(subheadingExtraTopBottomSpacing)
        }
    }
    
    override var footerParagraphStyle: NSParagraphStyle? {
        
        guard let paragraphStyle = super.footerParagraphStyle else {
            return nil
        }
        
        return modifiedParagraphStyleFromOriginalStyle(paragraphStyle)
    }
    
    override var subheadingParagraphStyle: NSParagraphStyle? {
        
        guard let paragraphStyle = super.subheadingParagraphStyle else {
            return nil
        }
        
        return modifiedParagraphStyleFromOriginalStyle(paragraphStyle)
    }
    
    private func modifiedParagraphStyleFromOriginalStyle(_ originalStyle: NSParagraphStyle) -> NSParagraphStyle? {
        
        if let mutParagraphStyle = originalStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutParagraphStyle.alignment = style == .minimal ? .center : .natural
            return mutParagraphStyle.copy() as? NSParagraphStyle
        }
        
        return originalStyle
    }
}

class ReadingListImportSurveyPanelViewController : ScrollableEducationPanelViewController {

    init(primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme, languageCode: String) {
        self.languageCode = languageCode
        super.init(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
        self.footerLinkAction = footerLinkAction
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private typealias LanguageCode = String
    private typealias URLString = String
    private let languageCode: LanguageCode
    private let privacyURLStrings: [LanguageCode: URLString] = [
        "en": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement",
        "ar": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/ar",
        "bn": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/bn",
        "fr": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/fr",
        "de": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/de",
        "hi": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/hi",
        "pt": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/pt-br",
        "es": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement/es",
        "ur": "https://foundation.wikimedia.org/wiki/Legal:Feedback_form_for_sharing_reading_lists_Privacy_Statement"]

    override func viewDidLoad() {
        super.viewDidLoad()
        heading = WMFLocalizedString("import-shared-reading-list-survey-prompt-title", languageCode: languageCode, value:"Could you help us improve \"Share reading lists\"?", comment:"Title of prompt to take a survey, displayed after user successfully imports a shared reading list.")
        subheading = WMFLocalizedString("import-shared-reading-list-survey-prompt-subtitle", languageCode: languageCode, value:"\"Share reading lists\" is a test feature and we need your feedback to improve or remove it.", comment:"Subtitle of prompt to take a survey, displayed after user successfully imports a shared reading list.")
        primaryButtonTitle = WMFLocalizedString("import-shared-reading-list-survey-prompt-button-take-survey", languageCode: languageCode, value:"Take survey", comment:"Title of action button on import reading list survey prompt, which takes user to external survey.")
        secondaryButtonTitle = WMFLocalizedString("import-shared-reading-list-survey-prompt-button-cancel", languageCode: languageCode, value:"Not now", comment:"Title of cancel button on import shared reading list survey prompt, which dismisses the prompt.")
        
        // TODO: Fix footer colors
        let footerFormat = WMFLocalizedString("import-shared-reading-list-survey-prompt-footer", languageCode: languageCode, value: "View our %1$@privacy statement%2$@. Survey powered by a third-party. View their %3$@privacy policy%4$@.", comment: "Title of footer button on import shared reading list survey prompt, which takes user to the privacy policy. Parameters:\n* %1$@ - app-specific non-text formatting, %2$@ - app-specific non-text formatting, %3$@ - app-specific non-text formatting, %4$@ - app-specific non-text formatting")
        
        guard let privacyURLString = privacyURLStrings[languageCode] ?? privacyURLStrings["en"] else {
            return
        }
        
        let footerHTML = String.localizedStringWithFormat(
            footerFormat,
            "<a href=\"\(privacyURLString)\">",
            "</a>",
            "<a href=\"https://policies.google.com/privacy\">",
            "</a>"
        )
        self.footerHTML = footerHTML
    }
    
    override var footerParagraphStyle: NSParagraphStyle? {
        
        guard let paragraphStyle = super.footerParagraphStyle else {
            return nil
        }
        
        return modifiedParagraphStyleFromOriginalStyle(paragraphStyle)
    }
    
    private func modifiedParagraphStyleFromOriginalStyle(_ originalStyle: NSParagraphStyle) -> NSParagraphStyle? {
        
        let semanticContentAttribute = MWKLanguageLinkController.semanticContentAttribute(forContentLanguageCode: languageCode)
        
        if let mutParagraphStyle = originalStyle.mutableCopy() as? NSMutableParagraphStyle {
            mutParagraphStyle.alignment = semanticContentAttribute == .forceRightToLeft ? .right : .natural
            return mutParagraphStyle.copy() as? NSParagraphStyle
        }
        
        return originalStyle
    }
}

class EnableReadingListSyncPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-syncing")
        heading = WMFLocalizedString("reading-list-sync-enable-title", value:"Turn on reading list syncing?", comment:"Title describing reading list syncing.")
        subheading = WMFLocalizedString("reading-list-sync-enable-subtitle", value:"Your saved articles and reading lists can now be saved to your Wikipedia account and synced across Wikipedia apps.", comment:"Subtitle describing reading list syncing.")
        primaryButtonTitle = WMFLocalizedString("reading-list-sync-enable-button-title", value:"Enable syncing", comment:"Title for button enabling reading list syncing.")
    }
}

class ErrorPanelViewController : ScrollableEducationPanelViewController {
    
    private let messageHtml: String
    private let button1Title: String
    private let button2Title: String?
    private let errorImage: UIImage?
    
    init(messageHtml: String, image: UIImage? = UIImage(named: "error-icon-large"), button1Title: String, button2Title: String?, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, subheadingLinkAction: ((URL) -> Void)?, theme: Theme) {
        self.messageHtml = messageHtml
        self.button1Title = button1Title
        self.button2Title = button2Title
        self.errorImage = image
        super.init(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, traceableDismissHandler: nil, hasPinnedButtons: true, theme: theme)
        self.subheadingLinkAction = subheadingLinkAction

    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image = errorImage
        subheadingHTML = messageHtml
        primaryButtonTitle = button1Title
        secondaryButtonTitle = button2Title
        imageHeightConstraint.constant = 50
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        evaluateConstraintsOnNewSize(view.frame.size)
        if scrollView.bounces {
            scrollView.flashScrollIndicators()
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        evaluateConstraintsOnNewSize(view.frame.size)
    }

    private func evaluateConstraintsOnNewSize(_ size: CGSize) {
        width = traitCollection.horizontalSizeClass == .compact ? 280 : size.width * 0.9
    }
}

class AddSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-add-saved-title", value:"Saved articles found", comment:"Title explaining saved articles were found.")
        subheading = WMFLocalizedString("reading-list-add-saved-subtitle", value:"There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?", comment:"Subtitle explaining that saved articles can be added to reading lists.")
        primaryButtonTitle = WMFLocalizedString("reading-list-add-saved-button-title", value:"Yes, add them to my reading lists", comment:"Title for button to add saved articles to reading list. The question being asked is: There are articles saved to your Wikipedia app. Would you like to keep them and merge with reading lists synced to your account?")
        secondaryButtonTitle = CommonStrings.readingListDoNotKeepSubtitle
    }
}

class LoginToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-login")
        heading = WMFLocalizedString("reading-list-login-title", value:"Sync your saved articles?", comment:"Title for syncing save articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = CommonStrings.readingListLoginButtonTitle
    }
}

@objc enum KeepSavedArticlesTrigger: Int {
    case logout, syncDisabled
}

class KeepSavedArticlesOnDevicePanelViewController : ScrollableEducationPanelViewController {
    private let trigger: KeepSavedArticlesTrigger
    
    init(triggeredBy trigger: KeepSavedArticlesTrigger, showCloseButton: Bool, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, dismissHandler: ScrollableEducationPanelDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool, theme: Theme) {
        self.trigger = trigger
        super.init(showCloseButton: showCloseButton, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, theme: theme)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        return nil
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-saved")
        heading = WMFLocalizedString("reading-list-keep-title", value: "Keep saved articles on device?", comment: "Title for keeping save articles on device.")
        primaryButtonTitle = WMFLocalizedString("reading-list-keep-button-title", value: "Yes, keep articles on device", comment: "Title for button to keep synced articles on device.")
        if trigger == .logout {
            subheading = CommonStrings.keepSavedArticlesOnDeviceMessage
            secondaryButtonTitle = CommonStrings.readingListDoNotKeepSubtitle
        } else if trigger == .syncDisabled {
            subheading = CommonStrings.keepSavedArticlesOnDeviceMessage + "\n\n" + WMFLocalizedString("reading-list-keep-sync-disabled-additional-subtitle", value: "Turning sync off will remove these articles from your account. If you remove them from your device they will not be recoverable by turning sync on again in the future.", comment: "Additional subtitle informing user that turning sync off will remove saved articles from their account.")
            secondaryButtonTitle = WMFLocalizedString("reading-list-keep-sync-disabled-remove-article-button-title", value: "No, remove articles from device and my Wikipedia account", comment: "Title for button that removes save articles from device and Wikipedia account.")
        }
    }
}
class SyncEnabledPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-lists-sync-enabled-disabled")
        heading = WMFLocalizedString("reading-list-sync-enabled-panel-title", value: "Sync is enabled on this account", comment: "Title for panel informing user that sync was enabled on their Wikipedia account on another device")
        subheading = WMFLocalizedString("reading-list-sync-enabled-panel-message", value: "Reading list syncing is enabled for this account. To stop syncing, you can turn sync off for this account by updating your settings.", comment: "Message for panel informing user that sync is enabled for their account.")
        primaryButtonTitle = CommonStrings.gotItButtonTitle
    }
}

class SyncDisabledPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-lists-sync-enabled-disabled")
        heading = WMFLocalizedString("reading-list-sync-disabled-panel-title", value: "Sync disabled", comment: "Title for panel informing user that sync was disabled on their Wikipedia account on another device")
        subheading = WMFLocalizedString("reading-list-sync-disabled-panel-message", value: "Reading list syncing has been disabled for your Wikipedia account on another device. You can turn sync back on by updating your settings.", comment: "Message for panel informing user that sync was disabled on their Wikipedia account on another device.")
        primaryButtonTitle = CommonStrings.gotItButtonTitle
    }
}

class EnableLocationPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "places-auth-arrow")
        heading = CommonStrings.localizedEnableLocationTitle
        primaryButtonTitle = CommonStrings.localizedEnableLocationButtonTitle
        footer = CommonStrings.localizedEnableLocationDescription
    }
}

class LoggedOutPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "logged-out-warning")
        heading = WMFLocalizedString("logged-out-title", value: "You have been logged out", comment: "Title for education panel letting user know they have been logged out.")
        subheading = WMFLocalizedString("logged-out-subtitle", value: "There was a problem authenticating your account. In order to sync your reading lists and edit under your user name please log back in.", comment: "Subtitle for letting user know there was a problem authenticating their account.")
        primaryButtonTitle = WMFLocalizedString("logged-out-log-back-in-button-title", value: "Log back in to your account", comment: "Title for button allowing user to log back in to their account")
        secondaryButtonTitle = WMFLocalizedString("logged-out-continue-without-logging-in-button-title", value: "Continue without logging in", comment: "Title for button allowing user to continue without logging back in to their account")
    }
}

class NotLoggedInPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "abuse-filter-flag")
        heading = WMFLocalizedString("panel-not-logged-in-title", value: "You are not logged in", comment: "Title for education panel letting user know they are not logged in.")
        
        let subheadingFormat = WMFLocalizedString("panel-not-logged-in-subtitle", value: "Your IP address will be publicly visible if you make any edits. If you %1$@log in%2$@ or %3$@create an account%4$@, your edits will be attributed to your username, along with other benefits.", comment: "Subtitle for letting user know that they are not logged in, after they attempt to publish an edit. Parameters:\n* %1$@ - app-specific text formatting - beginning bold text, %2$@ - app-specific text formatting - ending bold text, %3$@ - app-specific text formatting - beginning bold text, %4$@ - app-specific text formatting - ending bold text.")
        
        self.subheadingHTML = String.localizedStringWithFormat(
            subheadingFormat,
            "<b>",
            "</b>",
            "<b>",
            "</b>"
        )
        primaryButtonTitle = CommonStrings.loginOrCreateAccountTitle
        secondaryButtonTitle = WMFLocalizedString("panel-not-logged-in-continue-edit-action-title", value: "Edit without logging in", comment: "Title for button that continues publishing the edit anonymously.")
    }
}

class LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "reading-list-user")
        heading = WMFLocalizedString("reading-list-login-or-create-account-title", value:"Log in to sync saved articles", comment:"Title for syncing saved articles.")
        subheading = CommonStrings.readingListLoginSubtitle
        primaryButtonTitle = CommonStrings.loginOrCreateAccountTitle
    }
}

class LoginOrCreateAccountToToThankRevisionAuthorPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "diff-smile-heart")
        heading = WMFLocalizedString("diff-thanks-login-title", value:"Log in to send 'Thanks'", comment:"Title for thanks login panel.")
        subheading = WMFLocalizedString("diff-thanks-login-subtitle", value:"'Thanks' are an easy way to show appreciation for an editor's work on Wikipedia. You must be logged in to send 'Thanks'.", comment:"Subtitle for thanks login panel.")
        primaryButtonTitle = CommonStrings.loginOrCreateAccountTitle
        secondaryButtonTitle = CommonStrings.cancelActionTitle
    }
}

class ThankRevisionAuthorEducationPanelViewController : ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "diff-smile-heart")
        heading = WMFLocalizedString("diff-thanks-send-title", value:"Publicly send 'Thanks'", comment:"Title for sending thanks panel.")
        subheading = WMFLocalizedString("diff-thanks-send-subtitle", value:"'Thanks' are an easy way to show appreciation for an editor's work on Wikipedia. 'Thanks' cannot be undone and are publicly viewable.", comment:"Subtitle for sending thanks panel.")
        primaryButtonTitle = WMFLocalizedString("diff-thanks-send-button-title", value:"Send 'Thanks'", comment:"Title for sending thanks button.")
        secondaryButtonTitle = CommonStrings.cancelActionTitle
    }
}

class LimitHitForUnsortedArticlesPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        heading = WMFLocalizedString("reading-list-limit-hit-for-unsorted-articles-title", value: "Limit hit for unsorted articles", comment: "Title for letting the user know that the limit for unsorted articles was reached.")
        subheading = WMFLocalizedString("reading-list-limit-hit-for-unsorted-articles-subtitle", value:  "There is a limit of 5000 unsorted articles. Please sort your existing articles into lists to continue the syncing of unsorted articles.", comment: "Subtitle letting the user know that there is a limit of 5000 unsorted articles.")
        primaryButtonTitle = WMFLocalizedString("reading-list-limit-hit-for-unsorted-articles-button-title", value: "Sort articles", comment: "Title for button to sort unsorted articles.")
    }
}

class DescriptionPublishedPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "description-published")
        heading = WMFLocalizedString("description-published-title", value: "Description published!", comment: "Title for letting the user know their description change succeeded.")
        subheading = WMFLocalizedString("description-published-subtitle", value:  "You just made Wikipedia better for everyone", comment: "Subtitle encouraging user to continue editing")
        primaryButtonTitle = CommonStrings.doneTitle
        footer = WMFLocalizedString("description-published-footer", value: "You can also edit articles within this app. Try fixing typos and small sentences by clicking on the pencil icon next time", comment: "Title for footer explaining articles may be edited too - not just descriptions.")
    }
}

class EditPublishedPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "description-published")
        heading = WMFLocalizedString("edit-published", value: "Edit published", comment: "Title edit published panel letting user know their edit was saved.")
        subheading = WMFLocalizedString("edit-published-subtitle", value: "You just made Wikipedia better for everyone", comment: "Subtitle for letting users know their edit improved Wikipedia.")
        primaryButtonTitle = CommonStrings.doneTitle
    }
}

class NoInternetConnectionPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "no-internet-article")
        heading = CommonStrings.noInternetConnection
        subheading = WMFLocalizedString("no-internet-connection-article-reload", value: "A newer version of this article might be available, but cannot be loaded without a connection to the internet", comment: "Subtitle for letting users know article cannot be reloaded without internet connection.")
        primaryButtonTitle = WMFLocalizedString("no-internet-connection-article-reload-button", value: "Return to last saved version", comment: "Title for button to return to last saved version of article.")
    }
}

class DiffEducationalPanelViewController: ScrollableEducationPanelViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        image = UIImage(named: "panel-compare-revisions")
        heading = WMFLocalizedString("panel-compare-revisions-title", value: "Comparing revisions", comment: "Title for educational panel about comparing revisions")
        subheading = WMFLocalizedString("panel-compare-revisions-text", value: "Comparing revisions helps to show how an article has changed over time. Comparing two revisions of an article will show the difference between those revisions by highlighting any content that was changed.", comment: "Text for educational panel about comparing revisions")
        primaryButtonTitle = CommonStrings.gotItButtonTitle
    }
}

class LanguageVariantEducationalPanelViewController: ScrollableEducationPanelViewController {
    
    let languageCode: String
    let isFinalAlert: Bool
    
    // This panel can be displayed once or numerous times in a row when a user updates to an app version that adds new variant support for languages
    // When the secondaryButtonTapHandler is nil, a primary "Got it" button and no secondary button is diplayed.
    // When the secondaryButtonTapHandler has a value, the primary button is "Review your preferences" with a secondary "No thanks" button.
    init(primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, dismissHandler: ScrollableEducationPanelDismissHandler?, discardDismissHandlerOnPrimaryButtonTap: Bool = false, theme: Theme, languageCode: String) {
        self.languageCode = languageCode
        self.isFinalAlert = secondaryButtonTapHandler != nil
        super.init(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: discardDismissHandlerOnPrimaryButtonTap, theme: theme)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        heading = alertTitleForLanguageCode(languageCode)
        subheading = alertBodyForLanguageCode(languageCode) + "\n"
        subheadingTextAlignment = .natural
        primaryButtonTitle = isFinalAlert ? CommonStrings.variantsAlertPreferencesButton : CommonStrings.gotItButtonTitle
        secondaryButtonTitle = isFinalAlert ? CommonStrings.noThanksTitle : nil
    }
    
    func alertTitleForLanguageCode(_ languageCode: String) -> String {
        switch languageCode {
        case "crh": return CommonStrings.crimeanTatarVariantsAlertTitle
        case "gan": return CommonStrings.ganVariantsAlertTitle
        case "iu": return CommonStrings.inuktitutVariantsAlertTitle
        case "kk": return CommonStrings.kazakhVariantsAlertTitle
        case "ku": return CommonStrings.kurdishVariantsAlertTitle
        case "sr": return CommonStrings.serbianVariantsAlertTitle
        case "tg": return CommonStrings.tajikVariantsAlertTitle
        case "uz": return CommonStrings.uzbekVariantsAlertTitle
        case "zh": return CommonStrings.chineseVariantsAlertTitle
        case "shi": return CommonStrings.tachelhitVariantsAlertTitle
        default:
            assertionFailure("No language variant alert title for language code '\(languageCode)'")
            return ""
        }
    }

    func alertBodyForLanguageCode(_ languageCode: String) -> String {
        switch languageCode {
        case "crh": return CommonStrings.crimeanTatarVariantsAlertBody
        case "gan": return CommonStrings.ganVariantsAlertBody
        case "iu": return CommonStrings.inuktitutVariantsAlertBody
        case "kk": return CommonStrings.kazakhVariantsAlertBody
        case "ku": return CommonStrings.kurdishVariantsAlertBody
        case "sr": return CommonStrings.serbianVariantsAlertBody
        case "tg": return CommonStrings.tajikVariantsAlertBody
        case "uz": return CommonStrings.uzbekVariantsAlertBody
        case "zh": return CommonStrings.chineseVariantsAlertBody
        case "shi": return CommonStrings.tachelhitVariantsAlertBody
        default:
            assertionFailure("No language variant alert body for language code '\(languageCode)'")
            return ""
        }
    }
}

class NotificationsCenterOnboardingPushPanelViewController: ScrollableEducationPanelViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        heading = WMFLocalizedString("notifications-center-onboarding-panel-heading", value:"Turn on push notifications?", comment:"Title for Notifications Center onboarding panel.")
        subheading = WMFLocalizedString("notifications-center-onboarding-panel-subheading", value:"Wikipedia is a collaborative project and turning on push notifications can make it easier to keep up to date with messages, alerts, and \"thanks\" from fellow editors.", comment:"Message for Notifications Center onboarding panel.")
        primaryButtonTitle = WMFLocalizedString("notifications-center-onboarding-panel-primary-button", value:"Turn on push notifications", comment:"Title for Notifications Center onboarding panel primary button.")
        secondaryButtonTitle = WMFLocalizedString("notifications-center-onboarding-panel-secondary-button", value:"No thanks", comment:"Title for Notifications Center onboarding panel secondary button.")
    }
}

class AltTextExperimentPanelViewController: ScrollableEducationPanelViewController {
    let isFlowB: Bool

   init(showCloseButton: Bool, buttonStyle: ScrollableEducationPanelViewController.ButtonStyle = .legacyStyle, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme, isFlowB: Bool) {
       self.isFlowB = isFlowB
        super.init(showCloseButton: showCloseButton, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, traceableDismissHandler: traceableDismissHandler, theme: theme)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let imageRecsSubtitle = WMFLocalizedString("alt-text-modal-subtitle-image-recommendation", value: "The previous image is missing alt text. Add a description to the image for visually impaired readers?", comment: "Subtitle text for the alt text suggested edit prompt modal when the user is adding images from the add an image task")
        let regularEditSubtitle =  WMFLocalizedString("alt-text-modal-subtitle-regular-edit", value: "There is an image in this article that is missing alt text. Add a description for visually impaired readers?", comment: "Subtitle text for the alt text suggested edit prompt modal when the user is finished editing an article")
        image = WMFSFSymbolIcon.for(symbol: .textBelowPhoto, font: .title1, paletteColors: [theme.colors.link])
        heading = WMFLocalizedString("alt-text-modal-title", value: "Add missing image alt text?", comment: "Title text for the alt text suggested edit prompt modal")
        subheading = isFlowB ? imageRecsSubtitle : regularEditSubtitle
        primaryButtonTitle = WMFLocalizedString("alt-text-add-button-title", value: "Add", comment: "Title for the Add button on the alt text modal")
        secondaryButtonTitle = WMFLocalizedString("alt-text-do-not-add-button-title", value: "Do not add", comment: "Title for the Do Not Add button on the alt text modal")
    }
}

extension UIViewController {
    
    fileprivate func hasSavedArticles() -> Bool {
        let articleRequest = WMFArticle.fetchRequest()
        articleRequest.predicate = NSPredicate(format: "savedDate != NULL")
        articleRequest.fetchLimit = 1
        articleRequest.sortDescriptors = []
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: articleRequest, managedObjectContext: MWKDataStore.shared().viewContext, sectionNameKeyPath: nil, cacheName: nil)
        do {
            try fetchedResultsController.performFetch()
        } catch _ {
            return false
        }
        guard let fetchedObjects = fetchedResultsController.fetchedObjects else {
            return false
        }
        return !fetchedObjects.isEmpty
    }

    func wmf_showAnnouncementPanel(announcement: WMFAnnouncement, style: AnnouncementPanelViewController.Style = .standard, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme) {
        let panel = AnnouncementPanelViewController(announcement: announcement, style: style, primaryButtonTapHandler: { button, viewController in
            primaryButtonTapHandler?(button, viewController)
            self.dismiss(animated: true)
            // dismissHandler is called on viewDidDisappear
        }, secondaryButtonTapHandler: { button, viewController in
            secondaryButtonTapHandler?(button, viewController)
            self.dismiss(animated: true)
            // dismissHandler is called on viewDidDisappear
        }, footerLinkAction: footerLinkAction
        , traceableDismissHandler: { lastAction in
            traceableDismissHandler?(lastAction)
        }, theme: theme)
        present(panel, animated: true)
    }

    
    /// Shows new fundraising panel
    /// - Parameters:
    ///   - object: WKAsset object, that contains the announcement content
    ///   - primaryButtonTapHandler: Goes to donation
    ///   - secondaryButtonTapHandler: Maybe later - remind the user again after a certain period, within campain duration
    ///   - optionalButtonTapHandler: Dismiss the modal, does not show again
    func wmf_showFundraisingAnnouncement(theme: Theme, asset: WMFFundraisingCampaignConfig.WMFAsset, primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, optionalButtonTapHandler: ScrollableEducationPanelButtonTapHandler?,  footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, showMaybeLater: Bool) {

        let alert = FundraisingAnnouncementPanelViewController(announcement: asset, theme: theme, showOptionalButton: showMaybeLater, primaryButtonTapHandler: { button, viewController in
            primaryButtonTapHandler?(button, viewController)
        }, secondaryButtonTapHandler: { button, viewController in
            secondaryButtonTapHandler?(button, viewController)
            self.dismiss(animated: true)

        }, optionalButtonTapHandler: { button, viewController in
            optionalButtonTapHandler?(button, viewController)
            self.dismiss(animated: true)

        }, traceableDismissHandler: { lastAction in
            traceableDismissHandler?(lastAction)

        }, footerLinkAction: footerLinkAction)

        present(alert, animated: true)
    }

    /// Displays a blocked panel message, for use with fully resolved MediaWiki API blocked errors.
    /// - Parameters:
    ///   - messageHtml: Fully resolved message HTML to display
    ///   - linkBaseURL: base URL that relative links within messageHtml will reference
    ///   - currentTitle: Wiki title representing the article the user is currently working against. Used to help resolve relative links against.
    ///   - theme: initial theme for panel.
    func wmf_showBlockedPanel(messageHtml: String, linkBaseURL: URL, currentTitle: String, theme: Theme, image: UIImage? = UIImage(named: "error-icon-large"), linkLoggingAction: (() -> Void)? = nil) {
        
        let panel = ErrorPanelViewController(messageHtml: messageHtml, image: image, button1Title: CommonStrings.okTitle, button2Title: nil, primaryButtonTapHandler: { [weak self] _, _ in
            self?.dismiss(animated: true)
        }, secondaryButtonTapHandler: nil, subheadingLinkAction: { [weak self] url in

            guard let baseURL = linkBaseURL.wmf_URL(withTitle: currentTitle) else {
                return
            }
            
            linkLoggingAction?()

            let fullURL = baseURL.resolvingRelativeWikiHref(url.relativeString)

            let viewController = self?.presentingViewController ?? self?.presentedViewController
            viewController?.dismiss(animated: true) {
                self?.navigate(to: fullURL)
            }

        }, theme: theme)
        
        present(panel, animated: true)
    }
    
    /// Displays a panel message when abuse filter disallow error code is triggered, for use with fully resolved MediaWiki API blocked errors.
    /// - Parameters:
    ///   - messageHtml: Fully resolved message HTML to display
    ///   - linkBaseURL: base URL that relative links within messageHtml will reference
    ///   - currentTitle: Wiki title representing the article the user is currently working against. Used to help resolve relative links against.
    ///   - theme: initial theme for panel.
    ///   - goBackIsOnlyDismiss: Bool - Boolean for if the primary tap handler should dismiss the panel only, or dismiss and navigate the user two screens back. True is dismiss only, false also pops back two screens.
    func wmf_showAbuseFilterDisallowPanel(messageHtml: String, linkBaseURL: URL, currentTitle: String, theme: Theme, goBackIsOnlyDismiss: Bool) {
        
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler
        
        if goBackIsOnlyDismiss {
            primaryButtonTapHandler = { [weak self] _, _ in
                self?.dismiss(animated: true)
            }
        } else {
            primaryButtonTapHandler = { [weak self] _, _ in
                self?.dismiss(animated: true) {
                    
                    guard let viewControllers = self?.navigationController?.viewControllers,
                          viewControllers.count > 2 else {
                        return
                    }
                    
                    let remaining = viewControllers.prefix(viewControllers.count - 2)
                    
                    self?.navigationController?.setViewControllers(Array(remaining), animated: true)
                }
            }
        }
        let panel = ErrorPanelViewController(messageHtml: messageHtml, button1Title: CommonStrings.goBackTitle, button2Title: nil, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, subheadingLinkAction: { [weak self] url in

            guard let baseURL = linkBaseURL.wmf_URL(withTitle: currentTitle) else {
                return
            }

            let fullURL = baseURL.resolvingRelativeWikiHref(url.relativeString)

            self?.presentingViewController?.dismiss(animated: true) {
                self?.navigate(to: fullURL)
            }

        }, theme: theme)
        
        present(panel, animated: true)
    }
    
    /// Displays a panel message when abuse filter warning error code is triggered, for use with fully resolved MediaWiki API blocked errors.
    /// - Parameters:
    ///   - messageHtml: Fully resolved message HTML to display
    ///   - linkBaseURL: base URL that relative links within messageHtml will reference
    ///   - currentTitle: Wiki title representing the article the user is currently working against. Used to help resolve relative links against.
    ///   - theme: initial theme for panel.
    ///   - goBackIsOnlyDismiss: Bool - Boolean for if the primary tap handler should dismiss the panel only, or dismiss and navigate the user two screens back. True is dismiss only, false also pops back two screens.
    ///   - publishAnywayTapHandler: Handler triggered when the user taps "Publish anyway". Invoke the view controller's edit save method again.
    func wmf_showAbuseFilterWarningPanel(messageHtml: String, linkBaseURL: URL, currentTitle: String, theme: Theme, goBackIsOnlyDismiss: Bool, publishAnywayTapHandler: @escaping ScrollableEducationPanelButtonTapHandler) {
        
        let panel = ErrorPanelViewController(messageHtml: messageHtml, button1Title: CommonStrings.goBackTitle, button2Title: CommonStrings.publishAnywayTitle, primaryButtonTapHandler: { [weak self] _, _ in
            self?.dismiss(animated: true) {
                
                guard let viewControllers = self?.navigationController?.viewControllers,
                      viewControllers.count > 2 else {
                    return
                }
                
                let remaining = viewControllers.prefix(viewControllers.count - 2)
                
                self?.navigationController?.setViewControllers(Array(remaining), animated: true)
            }
        }, secondaryButtonTapHandler: publishAnywayTapHandler, subheadingLinkAction: { [weak self] url in

            guard let baseURL = linkBaseURL.wmf_URL(withTitle: currentTitle) else {
                return
            }

            let fullURL = baseURL.resolvingRelativeWikiHref(url.relativeString)

            self?.presentingViewController?.dismiss(animated: true) {
                self?.navigate(to: fullURL)
            }

        }, theme: theme)
        
        present(panel, animated: true)
    }
    
    func wmf_showReadingListImportSurveyPanel(primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler?, footerLinkAction: ((URL) -> Void)?, traceableDismissHandler: ScrollableEducationPanelTraceableDismissHandler?, theme: Theme, languageCode: String) {

        let panel = ReadingListImportSurveyPanelViewController(primaryButtonTapHandler: { button, viewController in
            primaryButtonTapHandler?(button, viewController)
            self.dismiss(animated: true)
            // dismissHandler is called on viewDidDisappear
        }, secondaryButtonTapHandler: { button, viewController in
            secondaryButtonTapHandler?(button, viewController)
            self.dismiss(animated: true)
            // dismissHandler is called on viewDidDisappear
        }, footerLinkAction: footerLinkAction, traceableDismissHandler: { lastAction in
            traceableDismissHandler?(lastAction)
        }, theme: theme, languageCode: languageCode)

        present(panel, animated: true)
    }
        
    @objc func wmf_showEnableReadingListSyncPanel(theme: Theme, oncePerLogin: Bool = false, didNotPresentPanelCompletion: (() -> Void)? = nil, dismissHandler: ScrollableEducationPanelDismissHandler? = nil) {
        if oncePerLogin {
            guard !UserDefaults.standard.wmf_didShowEnableReadingListSyncPanel() else {
                didNotPresentPanelCompletion?()
                return
            }
        }
        // SINGLETONTODO
        let dataStore = MWKDataStore.shared()
        let presenter = self.presentedViewController ?? self
        guard !isAlreadyPresenting(presenter),
              dataStore.authenticationManager.authStateIsPermanent,
              dataStore.readingListsController.isSyncRemotelyEnabled,
              !dataStore.readingListsController.isSyncEnabled else {
            didNotPresentPanelCompletion?()
            return
        }
        let enableSyncTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                guard self.hasSavedArticles() else {
                    dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
                    SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
                    return
                }
                self.wmf_showAddSavedArticlesToReadingListPanel(theme: theme)
            })
        }
        
        let panelVC = EnableReadingListSyncPanelViewController(showCloseButton: true, primaryButtonTapHandler: enableSyncTapHandler, secondaryButtonTapHandler: nil, dismissHandler: dismissHandler, theme: theme)
        
        presenter.present(panelVC, animated: true, completion: {
            UserDefaults.standard.wmf_setDidShowEnableReadingListSyncPanel(true)
            // we don't want to present the "Sync disabled" panel if "Enable sync" was presented, wmf_didShowSyncDisabledPanel will be set to false when app is paused.
            UserDefaults.standard.wmf_setDidShowSyncDisabledPanel(true)
            SettingsFunnel.shared.logEnableSyncPopoverImpression()
        })
    }
    
    @objc func wmf_showSyncDisabledPanel(theme: Theme, wasSyncEnabledOnDevice: Bool) {
        guard !UserDefaults.standard.wmf_didShowSyncDisabledPanel(),
            wasSyncEnabledOnDevice else {
                return
        }
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panel = SyncDisabledPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        let presenter = self.presentedViewController ?? self
        presenter.present(panel, animated: true) {
            UserDefaults.standard.wmf_setDidShowSyncDisabledPanel(true)
        }
    }
    
    private func isAlreadyPresenting(_ presenter: UIViewController) -> Bool {
        let presenter = self.presentedViewController ?? self
        guard presenter is WMFThemeableNavigationController else {
            return false
        }
        return presenter.presentedViewController != nil
    }
    
    @objc func wmf_showSyncEnabledPanelOncePerLogin(theme: Theme, wasSyncEnabledOnDevice: Bool) {
        let presenter = self.presentedViewController ?? self
        guard !isAlreadyPresenting(presenter),
            !UserDefaults.standard.wmf_didShowSyncEnabledPanel(),
            !wasSyncEnabledOnDevice else {
                return
        }
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        let panel = SyncEnabledPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        presenter.present(panel, animated: true) {
            UserDefaults.standard.wmf_setDidShowSyncEnabledPanel(true)
        }
    }
    
    fileprivate func wmf_showAddSavedArticlesToReadingListPanel(theme: Theme) {
        // SINGLETONTODO
        let dataStore = MWKDataStore.shared()
        let addSavedArticlesToReadingListsTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            dataStore.readingListsController.setSyncEnabled(true, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            SettingsFunnel.shared.logEnableSyncPopoverSyncEnabled()
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        
        let panelVC = AddSavedArticlesToReadingListPanelViewController(showCloseButton: false, primaryButtonTapHandler: addSavedArticlesToReadingListsTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: nil, theme: theme)
        
        present(panelVC, animated: true, completion: nil)
    }
    
    func wmf_showLoginViewController(category: EventCategoryMEP? = nil, theme: Theme, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {
        guard let loginVC = WMFLoginViewController.wmf_initialViewControllerFromClassStoryboard() else {
            assertionFailure("Expected view controller(s) not found")
            return
        }
        loginVC.loginSuccessCompletion = loginSuccessCompletion
        loginVC.loginDismissedCompletion = loginDismissedCompletion
        loginVC.category = category
        loginVC.apply(theme: theme)
        present(WMFThemeableNavigationController(rootViewController: loginVC, theme: theme), animated: true)
    }

    @objc func wmf_showLoggedOutPanel(theme: Theme, dismissHandler: @escaping ScrollableEducationPanelDismissHandler) {
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true) {
                self.presenter?.wmf_showLoginViewController(theme: theme, loginDismissedCompletion: {
                    self.presenter?.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme)
                })
            }
        }
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true) {
                self.presenter?.wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy: .logout, theme: theme)
            }
        }
        let panelVC = LoggedOutPanelViewController(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, theme: theme)

        presenter?.present(panelVC, animated: true)
    }
    
    @objc func wmf_showNotLoggedInUponPublishPanel(buttonTapHandler: ((Int) -> Void)?, theme: Theme) {
        
        let primaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { [weak self] _, _ in
            
            self?.dismiss(animated: true) { [weak self] in
                self?.wmf_showLoginViewController(theme: theme, loginSuccessCompletion: nil, loginDismissedCompletion: nil)
                buttonTapHandler?(0)
            }
            
        }
        
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { [weak self] _, _ in
            
            self?.dismiss(animated: true) {
                buttonTapHandler?(1)
            }
        }
        
        let panelVC = NotLoggedInPanelViewController(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: nil, theme: theme)
        panelVC.dismissWhenTappedOutside = true

        presenter?.present(panelVC, animated: true)
    }

    private var presenter: UIViewController? {
        guard view.window == nil else {
            return self
        }
        if presentedViewController is UINavigationController {
            return presentedViewController
        }
        return nil
    }

    @objc func wmf_showLoginOrCreateAccountToSyncSavedArticlesToReadingListPanel(theme: Theme, dismissHandler: ScrollableEducationPanelDismissHandler? = nil, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {
        LoginFunnel.shared.logLoginImpressionInSyncPopover()
        
        let loginToSyncSavedArticlesTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(category: .loginToSyncPopover, theme: theme, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: loginDismissedCompletion)
                LoginFunnel.shared.logLoginStartInSyncPopover()
            })
        }
        
        let panelVC = LoginOrCreateAccountToSyncSavedArticlesToReadingListPanelViewController(showCloseButton: true, primaryButtonTapHandler: loginToSyncSavedArticlesTapHandler, secondaryButtonTapHandler: nil, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        
        present(panelVC, animated: true)
    }

    func wmf_showLoginOrCreateAccountToThankRevisionAuthorPanel(category: EventCategoryMEP? = nil, theme: Theme, dismissHandler: ScrollableEducationPanelDismissHandler? = nil, tapLoginHandler: (() -> Void)? = nil, loginSuccessCompletion: (() -> Void)? = nil, loginDismissedCompletion: (() -> Void)? = nil) {

        let loginToThankTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            tapLoginHandler?()
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(category: category, theme: theme, loginSuccessCompletion: loginSuccessCompletion, loginDismissedCompletion: loginDismissedCompletion)
            })
        }
        
        let secondaryButtonTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true)
        }
        
        let panelVC = LoginOrCreateAccountToToThankRevisionAuthorPanelViewController(showCloseButton: false, primaryButtonTapHandler: loginToThankTapHandler, secondaryButtonTapHandler: secondaryButtonTapHandler, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        
        present(panelVC, animated: true)
    }

    func wmf_showThankRevisionAuthorEducationPanel(theme: Theme, sendThanksHandler: @escaping ScrollableEducationPanelButtonTapHandler, cancelHandler: @escaping ScrollableEducationPanelButtonTapHandler) {
        let panelVC = ThankRevisionAuthorEducationPanelViewController(showCloseButton: false, primaryButtonTapHandler: sendThanksHandler, secondaryButtonTapHandler: cancelHandler, dismissHandler: nil, discardDismissHandlerOnPrimaryButtonTap: true, theme: theme)
        present(panelVC, animated: true)
    }
    
    @objc func wmf_showLoginToSyncSavedArticlesToReadingListPanelOncePerDevice(theme: Theme) {
        // SINGLETONTODO
        let dataStore = MWKDataStore.shared()
        guard
            !dataStore.authenticationManager.authStateIsPermanent &&
            !UserDefaults.standard.wmf_didShowLoginToSyncSavedArticlesToReadingListPanel() &&
            !dataStore.readingListsController.isSyncEnabled
        else {
            return
        }
        
        LoginFunnel.shared.logLoginImpressionInSyncPopover()
        
        let loginToSyncSavedArticlesTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.presentedViewController?.dismiss(animated: true, completion: {
                self.wmf_showLoginViewController(category: .loginToSyncPopover,theme: theme)
                LoginFunnel.shared.logLoginStartInSyncPopover()
            })
        }
        
        let panelVC = LoginToSyncSavedArticlesToReadingListPanelViewController(showCloseButton: true, primaryButtonTapHandler: loginToSyncSavedArticlesTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        
        present(panelVC, animated: true, completion: {
            UserDefaults.standard.wmf_setDidShowLoginToSyncSavedArticlesToReadingListPanel(true)
        })
    }

    @objc(wmf_showKeepSavedArticlesOnDevicePanelIfNeededTriggeredBy:theme:completion:)
    func wmf_showKeepSavedArticlesOnDevicePanelIfNeeded(triggeredBy keepSavedArticlesTrigger: KeepSavedArticlesTrigger, theme: Theme, completion: (() -> Swift.Void)? = nil) {
        guard self.hasSavedArticles() else {
            completion?()
            return
        }
        
        let keepSavedArticlesOnDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            MWKDataStore.shared().readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: false, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let deleteSavedArticlesFromDeviceTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            MWKDataStore.shared().readingListsController.setSyncEnabled(false, shouldDeleteLocalLists: true, shouldDeleteRemoteLists: false)
            self.presentedViewController?.dismiss(animated: true, completion: nil)
        }
        let dismissHandler: ScrollableEducationPanelDismissHandler = {
            completion?()
        }
        
        let panelVC = KeepSavedArticlesOnDevicePanelViewController(triggeredBy: keepSavedArticlesTrigger, showCloseButton: false, primaryButtonTapHandler: keepSavedArticlesOnDeviceTapHandler, secondaryButtonTapHandler: deleteSavedArticlesFromDeviceTapHandler, dismissHandler: dismissHandler, discardDismissHandlerOnPrimaryButtonTap: false, theme: theme)
        
        present(panelVC, animated: true, completion: nil)
    }
    
    @objc func wmf_showLimitHitForUnsortedArticlesPanelViewController(theme: Theme, primaryButtonTapHandler: @escaping ScrollableEducationPanelButtonTapHandler, completion: @escaping () -> Void) {
        let panelVC = LimitHitForUnsortedArticlesPanelViewController(showCloseButton: true, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: completion)
    }

    @objc func wmf_showDescriptionPublishedPanelViewController(theme: Theme) {
        guard !UserDefaults.standard.didShowDescriptionPublishedPanel else {
            return
        }
        let doneTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.dismiss(animated: true, completion: nil)
        }
        let panelVC = DescriptionPublishedPanelViewController(showCloseButton: true, primaryButtonTapHandler: doneTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true) {
            UserDefaults.standard.didShowDescriptionPublishedPanel = true
        }
    }

    @objc func wmf_showEditPublishedPanelViewController(theme: Theme) {
        guard !UserDefaults.standard.wmf_didShowFirstEditPublishedPanel() else {
            return
        }

        let doneTapHandler: ScrollableEducationPanelButtonTapHandler = { _, _ in
            self.dismiss(animated: true, completion: nil)
        }
        let panelVC = EditPublishedPanelViewController(showCloseButton: false, primaryButtonTapHandler: doneTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: {
            UserDefaults.standard.wmf_setDidShowFirstEditPublishedPanel(true)
        })
    }

    @objc func wmf_showNoInternetConnectionPanelViewController(theme: Theme, primaryButtonTapHandler: @escaping ScrollableEducationPanelButtonTapHandler, completion: @escaping () -> Void) {
        let panelVC = NoInternetConnectionPanelViewController(showCloseButton: false, primaryButtonTapHandler: primaryButtonTapHandler, secondaryButtonTapHandler: nil, dismissHandler: nil, theme: theme)
        present(panelVC, animated: true, completion: completion)
    }
}
