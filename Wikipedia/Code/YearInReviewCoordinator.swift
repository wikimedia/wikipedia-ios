import UIKit
import PassKit
import SwiftUI
import WMFComponents
import WMFData
import CocoaLumberjackSwift

@objc(WMFYearInReviewCoordinator)
final class YearInReviewCoordinator: NSObject, Coordinator {

    var theme: Theme
    let dataStore: MWKDataStore

    var navigationController: UINavigationController
    private weak var viewModel: WMFYearInReviewViewModel?
    private let targetRects = WMFProfileViewTargetRects()
    let dataController: WMFYearInReviewDataController
    var donateCoordinator: DonateCoordinator?

    let yearInReviewDonateText = WMFLocalizedString("year-in-review-donate", value: "Donate", comment: "Year in review donate button")
    weak var badgeDelegate: YearInReviewBadgeDelegate?
    
    // When true, presents a toast when they exit the Intro slide. Toast explains that they can access later via Profile menu.
    public var needsExitFromIntroToast: Bool = false
    
    /// Used as a slide ID when performing actions on the intro slide
    public var introSlideLoggingID: String = "profile"

    private var languageCode: String? {
        return dataStore.languageLinkController.appLanguage?.languageCode
    }
    
    private var primaryAppLanguage: WMFProject {
        if let languageCode {
            return WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: nil))
        }
        
        return WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }

    var featureURL: URL? {
        
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }
        
        return WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "Wikipedia Year in Review"], section: nil, language: appLanguage)
    }
    
    var featureFAQURL: URL? {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return nil
        }
        
        return WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "Team", "Wikipedia Year in Review", "Frequently Asked Questions"], section: "Frequently asked questions", language: appLanguage)
    }
    
    var topReadBlogPost: String { "https://wikimediafoundation.org/news/2025/12/01/announcing-english-wikipedias-most-popular-articles-of-2025" }
    
    var aboutWikimediaURLString: String {
        
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return ""
        }
        
        let url = WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "About the Wikimedia Foundation"], section: nil, language: appLanguage)
        return url?.absoluteString ?? ""
    }
    
    var editingFAQURLString: String {
        guard let appLanguage = WMFDataEnvironment.current.primaryAppLanguage else {
            return ""
        }
        
        let url = WMFProject.mediawiki.translatedHelpURL(pathComponents: ["Wikimedia Apps", "iOS FAQ"], section: "Editing", language: appLanguage)
        return url?.absoluteString ?? ""
    }
    
    private func noncontributorTitle() -> String {
        return WMFLocalizedString("year-in-review-non-contributor-slide-title", value: "Unlock your contributor reward for next year!", comment: "Year in review, non contributor slide title")
    }
    
    private var localizedStrings: WMFYearInReviewViewModel.LocalizedStrings {
        return WMFYearInReviewViewModel.LocalizedStrings(
            donateButtonTitle: CommonStrings.donateTitle,
            doneButtonTitle: CommonStrings.doneTitle,
            shareButtonTitle: CommonStrings.shortShareTitle,
            nextButtonTitle: CommonStrings.nextTitle,
            finishButtonTitle: WMFLocalizedString("year-in-review-finish", value: "Finish", comment: "Year in review finish button. Displayed on last slide and dismisses feature view."),
            shareText: WMFLocalizedString("year-in-review-share-text", value: "Here's my Wikipedia Year In Review. Created with the Wikipedia iOS app", comment: "Text shared the Year In Review slides"),
            introV3Title: CommonStrings.exploreYIRTitlePersonalized,
            introV3Subtitle: CommonStrings.exploreYIRBodyV3,
            introV3Footer: CommonStrings.exploreYIRFooterV3,
            introV3PrimaryButtonTitle: CommonStrings.getStartedTitle,
            introV3SecondaryButtonTitle: CommonStrings.learnMoreTitle(),
            wIconAccessibilityLabel: WMFLocalizedString("year-in-review-wikipedia-w-accessibility-label", value: "Wikipedia w logo", comment: "Accessibility label for the Wikipedia w logo"),
            wmfLogoImageAccessibilityLabel: WMFLocalizedString("year-in-review-wmf-logo-accessibility-label", value: "Wikimedia Foundation logo", comment: "Accessibility label for the Wikimedia Foundation logo"),
            puzzleGlobeHandAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-explore", value: "An animated illustration of a hand holding the Wikipedia globe, which gradually transforms into a small puzzle piece, symbolizing individual contributions to the platform.", comment: "Accessibility description for the personalized explore slide."),
            puzzleWalkAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-you-read", value: "A puzzle piece with the Wikimedia logo walking in from the left.", comment: "Accessibility description for the personalized 'You Read' slide."),
            bytesAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-user-edits", value: "An animated illustration showing bytes stacking on top of each other, symbolizing the continuous creation of free knowledge.", comment: "Accessibility description for the personalized user edits slide."),
            clockAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-weekday", value: "A clock ticking, symbolizing the time spent by people reading Wikipedia.", comment: "Accessibility description for the personalized weekday slide."),
            stoneAccessibilityLabel: WMFLocalizedString("year-in-review-collective-languages", value: "An animated illustration of a stone engraved with inscriptions representing various languages, symbolizing how Wikipedia collaboratively builds knowledge from diverse cultures and regions.", comment: "Accessibility description for the collective languages slide."),
            compAccessibilityLabel: WMFLocalizedString("year-in-review-collective-article-views", value: "An animated illustration of a computer screen with a web browser open, actively navigating through a Wikipedia article.", comment: "Accessibility description for the collective article views slide."),
            skyAccessibilityLabel: WMFLocalizedString("year-in-review-collective-saved-articles", value: "A puzzle globe featuring Wikipedia's logo, representing global collaboration.", comment: "Accessibility description for the collective saved articles slide."),
            duoAccessibilityLabel: WMFLocalizedString("year-in-review-collective-edits", value: "An illustration of two Wikipedia puzzle pieces, each carrying a piece of information.", comment: "Accessibility description for the collective edits slide."),
            penballAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-your-edits-views", value: "An illustration featuring a Wikipedia puzzle piece alongside a pen.", comment: "Accessibility description for the personalized 'Your Edits Views' slide."),
            englishReadingSlideTitle: englishReadingSlideTitle,
            englishReadingSlideSubtitle: englishReadingSlideSubtitle,
            englishTopReadSlideTitle: WMFLocalizedString("microsite-yir-english-top-read-slide-title", value: "English Wikipedia’s most read articles", comment: "Top read slide title for English Year in Review."),
            englishTopReadSlideSubtitle: englishTopReadSlideSubtitle,
            englishSavedReadingSlideTitle: englishSavedReadingSlideTitle,
            englishSavedReadingSlideSubtitle: englishSavedReadingSlideSubtitle,
            englishEditsSlideTitle: englishEditsSlideTitle,
            englishEditsSlideSubtitle: englishEditsSlideSubtitle,
            englishEditsBytesSlideTitle: englishEditsBytesSlideTitle,
            englishEditsBytesSlideSubtitle: englishEditsBytesSlideSubtitle,
            collectiveLanguagesSlideTitle: collectiveLanguagesSlideTitle,
            collectiveLanguagesSlideSubtitle: collectiveLanguagesSlideSubtitle,
            collectiveArticleViewsSlideTitle: collectiveArticleViewsSlideTitle,
            collectiveArticleViewsSlideSubtitle: collectiveArticleViewsSlideSubtitle,
            collectiveSavedArticlesSlideTitle: collectiveSavedArticlesSlideTitle,
            collectiveSavedArticlesSlideSubtitle: collectiveSavedArticlesSlideSubtitle,
            collectiveAmountEditsSlideTitle: collectiveAmountEditsSlideTitle,
            collectiveAmountEditsSlideSubtitle: WMFLocalizedString("year-in-review-base-editors-subtitle", value: "The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information.", comment: "Year in review, collective edits count slide subtitle."),
            collectiveEditsPerMinuteSlideTitle: collectiveEditsPerMinuteSlideTitle,
            collectiveEditsPerMinuteSlideSubtitle: collectiveEditsPerMinuteSlideSubtitle,
            personalizedYouReadSlideTitleV3: personalizedYouReadSlideTitleV3(readCount: minutesRead:),
            personalizedYouReadSlideSubtitleV3: personalizedYouReadSlideSubtitleV3(readCount:),
            personalizedDateSlideTitleV3: WMFLocalizedString("year-in-review-personalized-date-title-v3", value: "You have clear reading patterns", comment: "Year in review, personalized slide title for users that displays the time / day of the week / month they read most."),
            personalizedDateSlideTimeV3: getLocalizedTime(hour:),
            personalizedDateSlideTimeFooterV3: WMFLocalizedString("year-in-review-personalized-date-time-footer-v3", value: "Favorite time to read", comment: "Year in review, personalized slide footer text below the time-of-day that users read the most."),
            personalizedDateSlideDayV3: getLocalizedDay(day:),
            personalizedDateSlideDayFooterV3: WMFLocalizedString("year-in-review-personalized-date-day-footer-v3", value: "Favorite day to read", comment: "Year in review, personalized slide footer text below the day-of-week that users read the most."),
            personalizedDateSlideMonthV3: getLocalizedMonth(month:),
            personalizedDateSlideMonthFooterV3: WMFLocalizedString("year-in-review-personalized-date-month-footer-v3", value: "Month you did the most reading", comment: "Year in review, personalized slide footer text below the month that users read the most."),
            personalizedSaveCountSlideTitle: personalizedSaveCountSlideTitle(saveCount:),
            personalizedSaveCountSlideSubtitle: personalizedSaveCountSlideSubtitle(saveCount:articleNames:),
            personalizedUserEditsSlideTitle: personzlizedUserEditsSlideTitle(editCount:),
            personzlizedUserEditsSlideSubtitleEN: personzlizedUserEditsSlideSubtitle(),
            personzlizedUserEditsSlideSubtitleNonEN: personzlizedUserEditsSlideSubtitle(),
            personalizedYourEditsViewedSlideTitle: personalizedYourEditsViewedSlideTitle(views:),
            personalizedYourEditsViewedSlideSubtitle: personalizedYourEditsViewedSlideSubtitle(views:),
            personalizedThankYouTitle: WMFLocalizedString("year-in-review-personalized-donate-title", value: "Your generosity helped keep Wikipedia thriving", comment: "Year in review, personalized donate slide title for users that donated at least once that year. "),
            personalizedThankYouSubtitle: personalizedThankYouSubtitle(languageCode:),
            personalizedMostReadCategoriesSlideTitle: WMFLocalizedString("year-in-review-most-read-categories-title", value: "Your most interesting categories", comment: "Year in review, personalized categories slide title"),
            personalizedMostReadCategoriesSlideSubtitle: personalizedMostReadCategoriesSlideSubtitle(items:),
            personalizedMostReadArticlesSlideTitle: WMFLocalizedString("year-in-review-personalized-most-read-articles-title", value: "Your top articles", comment: "Year in review, personalized most read articles slide title"),
            personalizedMostReadArticlesSlideSubtitle: personalizedMostReadArticlesSlideSubtitle(items:),
            personalizedLocationSlideTitle: personalizedLocationSlideTitle(countryOrOcean:),
            personalizedLocationSlideSubtitle: personalizedLocationSlideSubtitle(articleNames:),
            noncontributorTitle: noncontributorTitle(),
            noncontributorSubtitle: noncontributorSlideSubtitle(),
            noncontributorButtonText: CommonStrings.donateTitle,
            contributorTitle: WMFLocalizedString("year-in-review-contributor-slide-title", value: "New app icon unlocked for your home screen", comment: "Year in review title for contributors"),
            contributorSubtitle: contributorSlideSubtitle(isEditor:isDonator:),
            contributorGiftTitle: WMFLocalizedString("year-in-review-contributor-gift-title", value: "Activate new app icon", comment: "Year in review title for the new icon"),
            contributorGiftSubtitle: WMFLocalizedString("year-in-review-contributor-gift-subtitle", value: "If you don’t turn it on now, you can access it later in Settings under Theme.", comment: "Year in review subtitle for the new icon"),
            highlightsSlideTitle: WMFLocalizedString("year-in-review-highlights-title", value: "Thank you for spending your year with Wikipedia.", comment: "Title for year in review highlights slide"),
            highlightsSlideSubtitle: WMFLocalizedString("year-in-review-highlights-subtitle", value: "We look forward to next year!", comment: "Subtitle for year in review highlights slide"),
            highlightsSlideButtonTitle: WMFLocalizedString("year-in-review-highlights-button-title", value: "Share highlights", comment: "Title for the share button on Year in Review Highlights slide"),
            mostReadArticlesTitle: WMFLocalizedString("year-in-review-highlights-personalized-articles", value: "Articles I read the most", comment: "Title for the list of articles read the most in the year in review slide"),
            minutesReadTitle: WMFLocalizedString("year-in-review-highlights-reading-time", value: "Minutes read", comment: "Title for the minutes read in the Year in review highlights slide"),
            favoriteReadingDayTitle: WMFLocalizedString("year-in-review-highlights-favorite-day", value: "Favorite day to read", comment: "Title for the favorite day to read in the Year in review highlights slide"),
            articlesReadTitle: WMFLocalizedString("year-in-review-highlights-articles-read", value: "Articles read", comment: "Title for the articles read by a user in the Year in review highlights slide"),
            favoriteCategoriesTitle: WMFLocalizedString("year-in-review-highlights-categories", value: "Categories that interested me", comment: "Title for the top categories for an user in the Year in review highlights slide"),
            editedArticlesTitle: WMFLocalizedString("year-in-review-highlights-times-edited", value: "Times edited", comment: "Title for the number of articles edited by an user in the Year in review highlights slide"),
            enWikiTopArticlesTitle: WMFLocalizedString("year-in-review-highlights-english-articles", value: "Most read articles on English Wikipedia", comment: "Title for the list of most popular articles on English Wikipedia in the Year in review slide"),
            enWikiTopArticlesValue: enWikiTopArticlesValue,
            hoursSpentReadingTitle: WMFLocalizedString("year-in-review-highlights-collective-time-spent", value: "Hours spent reading", comment: "Title for the estimation collective hours spent reading Wikipedia in the Year in review highlights slide"),
            hoursSpentReadingValue: hoursSpentReadingValue,
            numberOfChangesMadeTitle: WMFLocalizedString("year-in-review-highlights-changes", value: "Changes editors made", comment: "Title for the number of changes editors made on Wikipedia in the Year in review highlights slide"),
            numberOfChangesMadeValue: numberOfChangesMadeValue,
            numberOfViewedArticlesTitle: WMFLocalizedString("year-in-review-highlights-articles-viewed", value: "Number of viewed articles", comment: "Title for the number of viewed articles in Wikipedia in the Year in review highlights slide"),
            numberOfViewedArticlesValue: numberOfViewedArticlesValue,
            numberOfReadingListsTitle: WMFLocalizedString("year-in-review-highlights-created-lists", value: "Number of reading lists created", comment: "Title for the number of reading lists created collectivelly in the Year in Review highlights slide"),
            numberOfEditsTitle: WMFLocalizedString("year-in-review-highlights-number-app-editors", value: "Edits on-app", comment: "Title for the number of edits using the Wikipedia app in the Year in review highlights slide"),
            numberOfEditsValue: numberOfEditsValue,
            editFrequencyTitle: WMFLocalizedString("year-in-review-highlights-edit-frequency", value: "How often Wikipedia was edited", comment: "Title for the frequency of edits on Wikipedia in the Year in review highlights slide"),
            editFrequencyValue: editFrequencyValue,
            logoCaption: CommonStrings.logoCaption
        )
    }

    @objc public init(navigationController: UINavigationController, theme: Theme, dataStore: MWKDataStore, dataController: WMFYearInReviewDataController) {
        self.navigationController = navigationController
        self.theme = theme
        self.dataStore = dataStore
        self.dataController = dataController
    }

    func formatNumber(_ number: NSNumber, fractionDigits: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: number) ?? "\(number)"
    }

    // MARK: - Base Slide Strings
    
    var collectiveLanguagesSlideTitle: String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-base-reading-title-updated", value: "Wikipedia was available in more than {{PLURAL:%1$d|%1$d language|%1$d languages}}", comment: "Year in review, collective reading article count slide title, %1$d is replaced with the number of languages available on Wikipedia, e.g. \"300\"")
        
        return String.localizedStringWithFormat(format, config.languages)
    }

    var collectiveLanguagesSlideSubtitle: String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-base-reading-subtitle-updated", value: "Wikipedia had {{PLURAL:%1$lld|%1$lld article|%1$lld articles}} across over {{PLURAL:%2$d|%2$d active language|%2$d active languages}}. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review, collective reading count slide subtitle. %1$lld is replaced with a formatted number of articles available across Wikipedia, shown in numeric form (e.g. 10,000,000). %2$d is replaced with the number of active languages available on Wikipedia (e.g. 300)")
        
        return String.localizedStringWithFormat(format, config.articles, config.languages)
    }

    var collectiveArticleViewsSlideTitle: String {
        
        guard let config = dataController.config else {
            return ""
        }

        let format = WMFLocalizedString("year-in-review-base-viewed-title-updated", value: "App users viewed Wikipedia articles {{PLURAL:%1$lld|%1$lld time|%1$lld times}}", comment: "Year in review, collective article view count slide title. %1$lld is replaced with the text representing the number of article views across Wikipedia on apps, shown in numeric form (e.g. 1,000,000,000).")

        return String.localizedStringWithFormat(format, config.viewsApps)
    }

    var collectiveArticleViewsSlideSubtitle: String {
        return WMFLocalizedString("year-in-review-base-viewed-subtitle", value: "For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact.", comment: "Year in review, collective article view count subtitle.")
    }

    var collectiveSavedArticlesSlideTitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-base-saved-title-updated", value: "App users had {{PLURAL:%1$lld|%1$lld saved article|%1$lld saved articles}}", comment: "Year in review, collective saved articles count slide title, %1$lld is replaced with the total number of saved articles on apps, shown in numeric form (e.g. 37,574,993).")

        return String.localizedStringWithFormat(format, config.savedArticlesApps)
    }
    
    var collectiveSavedArticlesSlideSubtitle: String {
        return WMFLocalizedString("year-in-review-base-saved-subtitle", value: "Adding articles to reading lists allows you to access articles even while offline. You can also log in to sync reading lists across devices.", comment: "Year in review, collective saved articles count slide subtitle.")
    }

    var collectiveAmountEditsSlideTitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-base-editors-title-updated", value: "Editors on the official Wikipedia apps made {{PLURAL:%1$lld|%1$lld edit|%1$lld edits}}", comment: "Year in review, collective edits count slide title, %1$lld is replaced with the number of edits made on apps, shown in numeric form (e.g. 124,356).")
        
        return String.localizedStringWithFormat(format, config.editsApps)
    }

    var collectiveEditsPerMinuteSlideTitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-base-edits-title-updated", value: "Wikipedia was edited {{PLURAL:%1$d|%1$d time|%1$d times}} per minute", comment: "Year in review, collective edits per minute slide title, %1$d is replaced with the number of edits per minute on Wikipedia across platforms (e.g. 342).")

        return String.localizedStringWithFormat(format, config.editsPerMinute)
    }

    var collectiveEditsPerMinuteSlideSubtitle: String {
        let format = WMFLocalizedString("year-in-review-base-edits-subtitle-updated", value: "Articles are collaboratively created and improved using reliable sources. All of us have knowledge to share, [learn how to participate](%1$@).", comment: "Year in review, collective edits per minute slide subtitle, %1$@ is replaced with a link to the Mediawiki Apps team FAQ about editing.")
        return String.localizedStringWithFormat(format, editingFAQURLString)
    }
    
    var enWikiTopArticlesValue: [String] {
        guard let config = dataController.config else {
            return []
        }
        
        return config.topReadEN
    }
    
    var hoursSpentReadingValue: String {
        guard let config = dataController.config else {
            return ""
        }
        
        return formatNumber(NSNumber(integerLiteral: config.hoursReadEN), fractionDigits: 0)
    }
    
    var numberOfChangesMadeValue: String {
        guard let config = dataController.config else {
            return ""
        }
        
        return formatNumber(NSNumber(integerLiteral: config.edits), fractionDigits: 0)
    }
    
    var numberOfViewedArticlesValue: String {
        guard let config = dataController.config else {
            return ""
        }
        
        return formatNumber(NSNumber(integerLiteral: config.viewsApps), fractionDigits: 0)
    }
    
    var numberOfEditsValue: String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        return formatNumber(NSNumber(integerLiteral: config.editsApps), fractionDigits: 0)
    }
    
    var editFrequencyValue: String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-highlights-edit-frequency-value", value: "{{PLURAL:%1$d|%1$d time|%1$d times}} per minute", comment: "Value for the frequency of edits on Wikipedia in the Year in review highlights slide. %1$d is replaced with the number of edits per minute.")
        
        return String.localizedStringWithFormat(format, config.editsPerMinute)
    }
    
    // MARK: - Contributor
    func contributorSlideSubtitle(isEditor: Bool, isDonator: Bool) -> String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        dataController.updateContributorStatus(isContributor: (isEditor || isDonator))

        let editorText = WMFLocalizedString("year-in-review-contributor-slide-subtitle-editor-updated", value: "Thank you for investing in the future of free knowledge.\n\nYour contributions as an editor in %1$@ are helping pave the way to a world of free information and as a result you have unlocked a custom contributor icon for Wikipedia on your home screen.", comment: "Year in review, contributor slide subtitle, when user has edited that year. %1$@ is replaced with the Year in Review target year (e.g. 2025).")

        let donorText = WMFLocalizedString("year-in-review-contributor-slide-subtitle-donor-updated", value: "Thank you for investing in the future of free knowledge.\n\nYour contributions as a donor in %1$@ are helping pave the way to a world of free information and as a result you have unlocked a custom contributor icon for Wikipedia on your home screen.", comment: "Year in review, contributor slide subtitle, when user has donated that year. %1$@ is replaced with the Year in Review target year (e.g. 2025).")

        let bothText = WMFLocalizedString("year-in-review-contributor-slide-subtitle-editor-and-donor-updated", value: "Thank you for investing in the future of free knowledge.\n\nYour contributions as a donor and editor in %1$@ are helping pave the way to a world of free information and as a result you have unlocked a custom contributor icon for Wikipedia on your home screen.", comment: "Year in review, contributor slide subtitle, when user has edited and donated that year.  %1$@ is replaced with the Year in Review target year (e.g. 2025).")

        if isEditor && isDonator {
            return String.localizedStringWithFormat(bothText, String(config.year))
        } else if isEditor {
            return String.localizedStringWithFormat(editorText, String(config.year))
        } else if isDonator {
            return String.localizedStringWithFormat(donorText, String(config.year))
        } else {
            return ""
        }
    }

    func noncontributorSlideSubtitle() -> String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let thisYear = config.year
        let nextYear = config.year + 1

        let format = WMFLocalizedString("year-in-review-noncontributor-slide-subtitle-updated", value: "We’re glad Wikipedia was part of your %1$@! Unlock a special reward in your %2$@ Year in Review by becoming a contributor—whether by [editing Wikipedia](%3$@) or by donating from the app to the [Wikimedia Foundation](%4$@), the non-profit behind it. If Wikipedia is useful to you, please consider donating to help sustain its future and keep it free, ad-free, trustworthy, and accessible to all. If you donated elsewhere, your support is deeply appreciated.", comment: "Year in review, noncontributor slide subtitle. %1$@ is replaced with the Year in Review target year (e.g. 2025). %2$@ is replaced with the Year in Review target year + 1 (e.g. 2026). %3$@ is replaced with a MediaWiki url with more information about editing. %4$@ is replaced with a MediaWiki url with more information about the Wikimedia Foundation. Do not alter markdown when translating.")

        return String.localizedStringWithFormat(format, String(thisYear), String(nextYear), editingFAQURLString, aboutWikimediaURLString)
    }
    
    // MARK: - English Slide Strings
    
    var englishReadingSlideTitle: String {
        
        guard let config = dataController.config else {
            return ""
        }
        let format = WMFLocalizedString(
            "microsite-yir-english-reading-slide-title-updated",
            value: "We spent {{PLURAL:%1$lld|%1$lld hour|%1$lld hours}} reading",
            comment: "Reading slide title for English Year in Review. %1$lld is replaced with the total number of hours read on English Wikipedia, shown in numeric form (e.g. 2,423,171,000)."
        )
        
        return String.localizedStringWithFormat(format, config.hoursReadEN)
    }
    
    var englishReadingSlideSubtitle: String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("microsite-yir-english-reading-slide-subtitle-updated", value: "People spent an estimated {{PLURAL:%1$lld|%1$lld hour|%1$lld hours}}—around {{PLURAL:%2$lld|%2$lld year|%2$lld years}}!—reading English Wikipedia in %3$@. Wikipedia is there when you want to learn about our changing world, win a bet among friends, or answer a curious child’s question.", comment: "Reading slide subtitle for English Year in Review. %1$lld is replaced with the total number of hours read on English Wikipedia, shown in numeric form (e.g. 2,423,171,000). %2$lld is replaced with the number of years estimation, shown in numeric form  (e.g. 275,000). %3$@ is replaced with the Year in Review target year (e.g. 2025).")
        return String.localizedStringWithFormat(format, config.hoursReadEN, config.yearsReadEN, String(config.year))
    }
    
    var englishReadingSlideSubtitleShort: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("microsite-yir-english-reading-slide-subtitle-short-updated", value: "People spent an estimated {{PLURAL:%1$lld|%1$lld hour|%1$lld hours}}—around {{PLURAL:%2$lld|%2$lld year|%2$lld years}}!—reading English Wikipedia in %3$@.", comment: "Shortened reading slide subtitle for English Year in Review. This shortened sentence is appended to the personalized reading slide for EN Wiki users. %1$lld is replaced with the total number of hours read on English Wikipedia, shown in numeric form (e.g. 2,423,171,000). %2$lld is replaced with the number of years estimation, shown in numeric form (e.g. 275,000). %3$@ is replaced with the Year in Review target year (e.g. 2025).")
        return String.localizedStringWithFormat(format, config.hoursReadEN, config.yearsReadEN, String(config.year))
    }

    var englishTopReadSlideSubtitle: String {
        
        guard let config = dataController.config,
              config.topReadEN.count == 5 else {
            return ""
        }
        
        // Individual top read items
        let item1 = config.topReadEN[0]
        let item2 = config.topReadEN[1]
        let item3 = config.topReadEN[2]
        let item4 = config.topReadEN[3]
        let item5 = config.topReadEN[4]
        
        let linkOpening = "<a href=\"\(topReadBlogPost)\">"
        let linkClosing = "</a>"
        
        let format = WMFLocalizedString(
            "microsite-yir-english-top-read-slide-subtitle-updated",
            value: "When people want to learn about our world, they turn to Wikipedia. The top 5 visited articles on English Wikipedia were:\n\n1. %1$@\n2. %2$@\n3. %3$@\n4. %4$@\n5. %5$@\n\nRead more in %6$@our dedicated blog post%7$@.",
            comment: "Top read slide subtitle for English Year in Review. %1$@ %2$@ %3$@ %4$@ %5$@ are replaced with article titles, %6$@ and %7$@ wrap the blog post link."
        )
        
        return String.localizedStringWithFormat(format, item1, item2, item3, item4, item5, linkOpening, linkClosing)
    }
    
    var englishSavedReadingSlideTitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("microsite-yir-english-saved-reading-slide-title-updated", value: "We had {{PLURAL:%1$lld|%1$lld saved article|%1$lld saved articles}}", comment: "Saved reading slide title for English Year in Review. %1$lld is replaced with the total number of saved articles by active app users, shown in numeric form (e.g. 37,574,993).")
        return String.localizedStringWithFormat(format, config.savedArticlesApps)
    }
    
    var englishSavedReadingSlideSubtitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("microsite-yir-english-saved-reading-slide-subtitle-updated", value: "Active app users had {{PLURAL:%1$lld|%1$lld saved article|%1$lld saved articles}} this year. Adding articles to reading lists allows you to access articles even while offline. You can also log in to sync reading lists across devices.", comment: "Saved reading slide subtitle for English Year in Review. %1$lld is replaced with the total number of saved articles by active app users, shown in numeric form (e.g. 37,574,993).")
        return String.localizedStringWithFormat(format, config.savedArticlesApps)
    }
    
    var englishEditsSlideTitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("microsite-yir-english-edits-slide-title-updated", value: "Editors made {{PLURAL:%1$lld|%1$lld change|%1$lld changes}} this year", comment: "Edits slide title for English Year in Review. %1$lld is replaced with the total number of edits made on Wikipedia across platforms, shown in numeric form (e.g. 81,987,181).")
        return String.localizedStringWithFormat(format, config.edits)
    }
    
    var englishEditsSlideSubtitle: String {
        guard let config = dataController.config else {
            return ""
        }

        let format = WMFLocalizedString("microsite-yir-english-edits-slide-subtitle-updated", value: "Volunteers made {{PLURAL:%1$lld|%1$lld change|%1$lld changes}} across over {{PLURAL:%2$d|%2$d different language edition|%2$d different language editions}} of Wikipedia. {{PLURAL:%3$lld|%3$lld change|%3$lld changes}} were made on English Wikipedia. Every hour of every day, volunteers are working to improve Wikipedia.", comment: "Edits slide subtitle for English Year in Review. %1$lld is replaced by the total number of edits on Wikipedia across platforms, shown in numeric form (e.g. 81,987,181). %2$d is replaced by the total number of languages on Wikipedia (e.g. 300). %3$lld is replaced by the total number of edits on English Wikipedia across platforms, shown in numeric form (e.g. 31,000,000).")
        return String.localizedStringWithFormat(format, config.edits, config.languages, config.editsEN)
    }
    
    var englishEditsBytesSlideTitle: String {
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("microsite-yir-english-edits-bytes-slide-title-updated",value: "{{PLURAL:%1$lld|%1$lld byte|%1$lld bytes}} added", comment: "Edits bytes slide title for English Year in Review. %1$lld is replaced with the number of bytes added to English Wikipedia, shown in numeric form (e.g. 1,000,000,000).")
        return String.localizedStringWithFormat(format, config.bytesAddedEN)
    }

    var englishEditsBytesSlideSubtitle: String {
        
        guard let config = dataController.config else {
            return ""
        }

        let format = WMFLocalizedString(
            "microsite-yir-english-edits-bytes-slide-subtitle-updated",
            value: "In %1$@, volunteers added {{PLURAL:%2$lld|%2$lld byte|%2$lld bytes}} to English Wikipedia. The sum of all their work together leads to a steadily improving, fact-based, and reliable knowledge resource that they give to the world. All of us have knowledge to share, [learn how to participate](%3$@).",
            comment: "Edits bytes slide subtitle for English Year in Review. %1$@ is replaced with the Year in Review target year (e.g. 2025). %2$lld is replaced with the number of bytes added to English Wikipedia, shown in numeric form (e.g. 1,000,000,000). %3$@ is replaced by link to learn to participate."
        )

        return String.localizedStringWithFormat(format, String(config.year), config.bytesAddedEN, editingFAQURLString)
    }
    
    // MARK: - Personalized Slide Strings

    func personalizedYouReadSlideTitleV3(readCount: Int, minutesRead: Int) -> String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-personalized-reading-title-v3-format-updated", value: "You spent {{PLURAL:%1$d|%1$d minute|%1$d minutes}} reading {{PLURAL:%2$d|%2$d article|%2$d articles}} in %3$@", comment: "Year in review, personalized reading article count slide title for users that read articles. %1$d is replaced with the number of minutes the user spent reading and %2$d is replaced with the number of articles the user read in 2025. %3$@ is replaced with the Year in Review target year.")
        return String.localizedStringWithFormat(format, minutesRead, readCount, String(config.year))
    }

    func percentileRange(for readCount: Int) -> String? {
        
        guard let config = dataController.config else {
            return ""
        }
        
        var identifier: String? = nil
        for topReadPercentage in config.topReadPercentages {
            
            guard let max = topReadPercentage.max else {
                if readCount >= topReadPercentage.min {
                    identifier = topReadPercentage.identifier
                    break
                }
                continue
            }
            
            if readCount >= topReadPercentage.min && readCount <= max {
                identifier = topReadPercentage.identifier
            }
        }
        
        guard let identifier else {
            return nil
        }
        
        switch identifier {
        case "50":
            return WMFLocalizedString("percentile-50", value: "50", comment: "50th percentile range")
        case "40":
            return WMFLocalizedString("percentile-40", value: "40", comment: "40th percentile range")
        case "30":
            return WMFLocalizedString("percentile-30", value: "30", comment: "30th percentile range")
        case "20":
            return WMFLocalizedString("percentile-20", value: "20", comment: "20th percentile range")
        case "10":
            return WMFLocalizedString("percentile-10", value: "10", comment: "10th percentile range")
        case "5":
            return WMFLocalizedString("percentile-5", value: "5", comment: "5th percentile range")
        case "1":
            return WMFLocalizedString("percentile-1", value: "1", comment: "1st percentile range")
        case "0.01":
            return WMFLocalizedString("percentile-0.01", value: "0.01", comment: "0.01th percentile range")
        default:
            return nil
        }
    }

    func personalizedYouReadSlideSubtitleV3(readCount: Int) -> String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let secondSentence: String
        if primaryAppLanguage.isEnglishWikipedia {
            secondSentence = englishReadingSlideSubtitleShort
        } else {
            secondSentence = collectiveLanguagesSlideSubtitle
        }
        
        if readCount < 336 {
            return secondSentence
        } else {
            let percentageString = percentileRange(for: readCount)
            
            let format = WMFLocalizedString(
                "year-in-review-personalized-reading-subtitle-format-v3-updated",
                value: "We estimate that puts you in the top **PERCENT** of Wikipedia readers globally. The average person reads {{PLURAL:%1$d|%1$d article|%1$d articles}} a year.",
                comment: "Year in review, personalized reading article count slide subtitle for users that read articles. **PERCENT** is the percentage number (i.e. '25%'), do not adjust it, percentage sign is added via the client. %1$d is the average number of articles read per user."
            )
            
            if let percentageString = percentageString {
                let firstSentence = String.localizedStringWithFormat(format, config.averageArticlesReadPerYear)
                    .replacingOccurrences(of: "**PERCENT**", with: "<b>\(percentageString)%</b>")
                
                return "\(firstSentence)\n\n\(secondSentence)"
            }
        }
        return secondSentence
    }
    
    func getLocalizedMonth(month: Int) -> String {
        return DateFormatter().monthSymbols[month - 1]
    }
    
    func getLocalizedTime(hour: Int) -> String {
        let localizedTime: String
        switch hour {
        case 5...11:
            localizedTime = WMFLocalizedString("year-in-review-time-morning",value: "Morning", comment: "Localized name for morning time period (5:00AM-11:59PM).")
        case 12:
            localizedTime = WMFLocalizedString("year-in-review-time-midday",value: "Midday", comment: "Localized name for midday time period (12:00PM-12:59PM).")
        case 13...16:
            localizedTime = WMFLocalizedString("year-in-review-time-afternoon",value: "Afternoon", comment: "Localized name for afternoon time period (1:00PM-4:59PM).")
        case 17...20:
            localizedTime = WMFLocalizedString("year-in-review-time-evening",value: "Evening", comment: "Localized name for evening time period (5:00PM-8:59 PM).")
        case 21...23:
            localizedTime = WMFLocalizedString("year-in-review-time-night",value: "Night", comment: "Localized name for night time period (9:00PM-11:59PM).")
        default:
            localizedTime = WMFLocalizedString("year-in-review-time-late-night",value: "Late night", comment: "Localized name for late night time period (12:00AM-4:59AM).")
        }
        return localizedTime
    }
    
    func getLocalizedDay(day: Int) -> String {
        let localizedDay: String
        switch day {
        case 1: // Sunday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-sunday",
                value: "Sundays",
                comment: "Localized name for Sunday in plural form."
            )
        case 2: // Monday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-monday",
                value: "Mondays",
                comment: "Localized name for Monday in plural form."
            )
        case 3: // Tuesday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-tuesday",
                value: "Tuesdays",
                comment: "Localized name for Tuesday in plural form."
            )
        case 4: // Wednesday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-wednesday",
                value: "Wednesdays",
                comment: "Localized name for Wednesday in plural form."
            )
        case 5: // Thursday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-thursday",
                value: "Thursdays",
                comment: "Localized name for Thursday in plural form."
            )
        case 6: // Friday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-friday",
                value: "Fridays",
                comment: "Localized name for Friday in plural form."
            )
        case 7: // Saturday
            localizedDay = WMFLocalizedString(
                "year-in-review-day-saturday",
                value: "Saturdays",
                comment: "Localized name for Saturday in plural form."
            )
        default:
            localizedDay = "Invalid day"
        }
        
        return localizedDay
    }

    func personzlizedUserEditsSlideTitle(editCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-title-format-updated", value: "You edited {{PLURAL:%1$d|%1$d time|%1$d times}}", comment: "Year in review, personalized editing article count slide title for users that edited articles. %1$d is replaced with the number of edits the user made.")
        return String.localizedStringWithFormat(format, editCount)
    }
    
    func personzlizedUserEditsSlideSubtitle() -> String {
        return "\(personzlizedUserEditsSlideSubtitleFirstSentence()) \(personzlizedUserEditsSlideSubtitleSecondSentence())"
    }

    func personzlizedUserEditsSlideSubtitleFirstSentence() -> String {
        return WMFLocalizedString("year-in-review-personalized-editing-subtitle-1", value: "Thank you for being one of the volunteer editors making a difference on Wikimedia projects around the world.", comment: "Year in review, personalized editing article count slide subtitle for users that edited articles.")
    }
    
    func personzlizedUserEditsSlideSubtitleSecondSentence() -> String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let format = WMFLocalizedString("year-in-review-personalized-editing-subtitle-2-updated", value: "Volunteers like you made {{PLURAL:%1$lld|%1$lld change|%1$lld changes}} across {{PLURAL:%2$d|%2$d different language edition|%2$d different language editions}} of Wikipedia.", comment: "Year in review, personalized editing article count slide subtitle for users that edited articles. %1$lld is replaced with the number of edits made by volunteers, shown in numeric form (e.g. 81,987,181). %2$d is replaced with the number of Wikipedia languages.")
        return String.localizedStringWithFormat(format, config.edits, config.languages)
    }
    
    func personalizedYourEditsViewedSlideTitle(views: Int) -> String {
        
        let format = WMFLocalizedString(
            "year-in-review-personalized-edit-views-title-format-updated",
            value: "Your edits have been viewed more than {{PLURAL:%1$lld|%1$lld time|%1$lld times}} recently",
            comment: "Year in review, personalized slide title for users that display how many views their edits have. %1$lld is replaced with the amount of edit views, shown in numeric form (e.g. 124,356)."
        )
        
        return String.localizedStringWithFormat(format, views)
    }
    
    func personalizedYourEditsViewedSlideSubtitle(views: Int) -> String {
        
        let format = WMFLocalizedString(
            "year-in-review-personalized-edit-views-subtitle-format-updated",
            value: "Readers around the world appreciate your contributions. In the last 2 months, articles you've edited have received {{PLURAL:%1$lld|%1$lld view|%1$lld total views}}. Thanks to editors like you, Wikipedia is a steadily improving, fact-based, and reliable knowledge resource for the world.",
            comment: "Year in review, personalized slide subtitle for users that display how many views their edits have. %1$lld is replaced with the amount of edit views, shown in numeric form (e.g. 124,356)."
        )

        return String.localizedStringWithFormat(format, views)
    }

    func personalizedThankYouSubtitle(languageCode: String?) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-donate-subtitle", value: "Thank you for investing in the future of free knowledge. This year, the Wikimedia Foundation improved the technology to serve every reader and volunteer better, developed tools that empower collaboration, and supported Wikipedia in more languages. [Learn more about our work](%1$@).", comment: "Year in review, personalized donate slide subtitle for users that donated at least once that year. %1$@ is replaced with a MediaWiki url with more information about WMF. Do not alter markdown when translating.")
        return String.localizedStringWithFormat(format, aboutWikimediaURLString)
    }

    func personalizedSaveCountSlideTitle(saveCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-saved-title-format", value: "You saved {{PLURAL:%1$d|%1$d article|%1$d articles}}", comment: "Year in review, personalized saved articles slide subtitle. %1$d is replaced with the number of articles the user saved.")
        return String.localizedStringWithFormat(format, saveCount)
    }

    func personalizedSaveCountSlideSubtitle(saveCount: Int, articleNames: [String]) -> String {
        
        guard let config = dataController.config else {
            return ""
        }
        
        let articleName1 = articleNames.count >= 1 ? "<b>\(articleNames[0])</b>" : ""
        let articleName2 = articleNames.count >= 2 ? "<b>\(articleNames[1])</b>" : ""
        let articleName3 = articleNames.count >= 3 ? "<b>\(articleNames[2])</b>" : ""

        let format = WMFLocalizedString(
            "year-in-review-personalized-saved-subtitle-format-v3-updated",
            value: "These articles included %1$@, %2$@, and %3$@. Each saved article reflects your interests and helps build a personalized knowledge base on Wikipedia.\n\nActive app users had {{PLURAL:%4$lld|%4$lld saved article|%4$lld saved articles}} this year.",
            comment: "Year in review, personalized saved articles slide subtitle. %1$@, %2$@ and %3$@ are replaced with up to three article names the user saved (each enclosed in <b> tags). %4$lld is replaced with the total number of saved articles across active app users, shown in numeric form (e.g. 37,574,993)."
        )
        
        return String.localizedStringWithFormat(format, articleName1, articleName2, articleName3, config.savedArticlesApps)
    }
    
    func personalizedListSlideSubtitle(items: [String]) -> String {
        
        var listItems: String = ""
        for (index, category) in items.enumerated() {
            listItems += String.localizedStringWithFormat("%d. \(category)\n", index + 1)
        }

        return "\(listItems)"
    }
    
    func personalizedMostReadCategoriesSlideSubtitle(items: [String]) -> String {
        let format = WMFLocalizedString("year-in-review-categories-slide-subtitle", value: "Categories group articles on similar subjects together. In 2025, you visited articles in these interesting categories multiple times.\n\n%1$@", comment: "Year in review categories slide subtitle, $1 is the list of top categories.")
        return String.localizedStringWithFormat(format, personalizedListSlideSubtitle(items: items))
    }
    
    func personalizedMostReadArticlesSlideSubtitle(items: [String]) -> String {
        let format = WMFLocalizedString("year-in-review-articles-slide-subtitle", value: "Here were the articles you visited the most in 2025:\n%1$@", comment: "Year in review articles slide subtitle, $1 is the list of top articles.")
        return String.localizedStringWithFormat(format, personalizedListSlideSubtitle(items: items))
    }
    
    func personalizedLocationSlideTitle(countryOrOcean: String) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-location-title-format-updated", value: "Articles you read are closest to %1$@", comment: "Year in review, personalized location slide title. %1$@ is replaced with a country or ocean name.")
        return String.localizedStringWithFormat(format, countryOrOcean)
    }
    
    func personalizedLocationSlideSubtitle(articleNames: [String]) -> String {
        
        switch articleNames.count {
        case 1:
            let format = WMFLocalizedString("year-in-review-personalized-location-subtitle-format-1", value: "You read about %2$@%1$@%3$@.", comment: "Year in review, personalized location slide subtitle. %1$@ is replaced with an article name in the area they most read about. %2$@ and %3$@ are enclosing tags to make the name bold.")
            return String.localizedStringWithFormat(format, articleNames[0], "<b>", "</b>")
        case 2:
            let format = WMFLocalizedString("year-in-review-personalized-location-subtitle-format-2", value: "You read about %3$@%1$@%4$@ and %3$@%2$@%4$@.", comment: "Year in review, personalized location slide subtitle. %1$@ and %2$@ are replaced with article names in the area they most read about, %3$@ and %4$@ are enclosing tags to make the names bold.")
            return String.localizedStringWithFormat(format, articleNames[0], articleNames[1], "<b>", "</b>")
        case 3:
            let format = WMFLocalizedString("year-in-review-personalized-location-subtitle-format-3", value: "You read about %4$@%1$@%5$@, %4$@%2$@%5$@, and %4$@%3$@%5$@.", comment: "Year in review, personalized location slide subtitle. %1$@, %2$@ and %3$@ are replaced with article names in the area they most read about, %4$@ and %5$@ are enclosing tags to make the names bold.")
            return String.localizedStringWithFormat(format, articleNames[0], articleNames[1], articleNames[2], "<b>", "</b>")
        default:
            assertionFailure("Unexpected number of article names passed in, should be 1-3")
            return ""
        }
    }

    // MARK: - Funcs

    @discardableResult
    func start() -> Bool {
        
        let appShareLink = WMFYearInReviewDataController.appShareLink
        let hashtag = "#WikipediaYearInReview"
        let plaintextURL = primaryAppLanguage.isEnglishWikipedia ? "wikimediafoundation.org/2025articles" : "wikimediafoundation.org/yir25"
        let viewModel = WMFYearInReviewViewModel(
            localizedStrings: localizedStrings,
            shareLink: appShareLink,
            hashtag: hashtag,
            plaintextURL: plaintextURL,
            introSlideLoggingID: self.introSlideLoggingID,
            coordinatorDelegate: self,
            loggingDelegate: self,
            badgeDelegate: badgeDelegate,
            isUserPermanent: dataStore.authenticationManager.authStateIsPermanent,
            primaryAppLanguage: primaryAppLanguage,
            toggleAppIcon: { isNew in
                AppIconUtility.shared.updateAppIcon(isNew: isNew)
                DonateFunnel.shared.logYearInReviewDonateSlideDidToggleAppIcon(isOn: isNew)
            },
            isIconOn: AppIconUtility.shared.isNewIconOn,
            populateYearInReviewReport: populateYearInReviewReport
        )
        
        let yirView = WMFYearInReviewView(viewModel: viewModel)

        self.viewModel = viewModel
        let finalView = yirView.environmentObject(targetRects)
        let hostingController = UIHostingController(rootView: finalView)
        hostingController.modalPresentationStyle = .pageSheet

        if let sheetPresentationController = hostingController.sheetPresentationController {
            sheetPresentationController.detents = [.large()]
            sheetPresentationController.prefersGrabberVisible = false
        }

        hostingController.presentationController?.delegate = self

        (self.navigationController as? WMFComponentNavigationController)?.turnOnForcePortrait()
        navigationController.present(hostingController, animated: true, completion: nil)
        return true
    }
    
    func setupForFeatureAnnouncement(introSlideLoggingID: String) {
        needsExitFromIntroToast = true
        self.introSlideLoggingID = introSlideLoggingID
    }
    
    func resetFromFeatureAnnouncement() {
        needsExitFromIntroToast = false
        introSlideLoggingID = "profile"
    }
    
    func populateYearInReviewReport() async throws {
       guard let language  = dataStore.languageLinkController.appLanguage?.languageCode,
             let countryCode = Locale.current.region?.identifier
       else { return }
       let wmfLanguage = WMFLanguage(languageCode: language, languageVariantCode: nil)
       let project = WMFProject.wikipedia(wmfLanguage)
       
       var userId: Int?
       var globalUserId: Int?

       if let siteURL = dataStore.languageLinkController.appLanguage?.siteURL,
          let permanentUser = dataStore.authenticationManager.permanentUser(siteURL: siteURL) {
           userId = permanentUser.userID
           globalUserId = permanentUser.globalUserID
       }
       
        let yirDataController = try WMFYearInReviewDataController()
        try await yirDataController.populateYearInReviewReportData(
            for: WMFYearInReviewDataController.targetYear,
            countryCode: countryCode,
            primaryAppLanguageProject: project,
            username: dataStore.authenticationManager.authStatePermanentUsername,
            userID: userId,
            globalUserID: globalUserId,
            savedSlideDataDelegate: dataStore.savedPageList,
            legacyPageViewsDataDelegate: dataStore)
   }

    private func presentSurveyIfNeeded() {
        if !self.dataController.hasPresentedYiRSurvey {
            let surveyVC = surveyViewController()
            navigationController.present(surveyVC, animated: true, completion: {
                DonateFunnel.shared.logYearInReviewSurveyDidAppear()
            })
            self.dataController.hasPresentedYiRSurvey = true
        }
    }

    private func surveyViewController() -> UIViewController {
        let title = WMFLocalizedString("year-in-review-survey-title", value: "Satisfaction survey", comment: "Year in review survey title. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let subtitle = WMFLocalizedString("year-in-review-survey-subtitle", value: "Help improve the Wikipedia Year in Review. Are you satisfied with this feature? What would like to see next year?", comment: "Year in review survey subtitle. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let additionalThoughts = WMFLocalizedString("year-in-review-survey-additional-thoughts", value: "Any additional thoughts?", comment: "Year in review survey placeholder for additional thoughts textfield. Survey is displayed after user has viewed the last slide of their year in review feature.")

        let verySatisfied = WMFLocalizedString("year-in-review-survey-very-satisfied", value: "Very satisfied", comment: "Year in review survey option 1 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let satisfied = WMFLocalizedString("year-in-review-survey-satisfied", value: "Satisfied", comment: "Year in review survey option 2 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let neutral = WMFLocalizedString("year-in-review-survey-neutral", value: "Neutral", comment: "Year in review survey option 3 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let unsatisfied = WMFLocalizedString("year-in-review-survey-unsatisfied", value: "Unsatisfied", comment: "Year in review survey option 4 text. Survey is displayed after user has viewed the last slide of their year in review feature.")
        let veryUnsatisfied = WMFLocalizedString("year-in-review-survey-very-unsatisfied", value: "Very unsatisfied", comment: "Year in review survey option 5 text. Survey is displayed after user has viewed the last slide of their year in review feature.")

        let surveyLocalizedStrings = WMFSurveyViewModel.LocalizedStrings(
            title: title,
            cancel: CommonStrings.cancelActionTitle,
            submit: CommonStrings.surveySubmitActionTitle,
            subtitle: subtitle,
            instructions: nil,
            otherPlaceholder: additionalThoughts
        )

        let surveyOptions = [
            WMFSurveyViewModel.OptionViewModel(text: verySatisfied, apiIdentifer: "1"),
            WMFSurveyViewModel.OptionViewModel(text: satisfied, apiIdentifer: "2"),
            WMFSurveyViewModel.OptionViewModel(text: neutral, apiIdentifer: "3"),
            WMFSurveyViewModel.OptionViewModel(text: unsatisfied, apiIdentifer: "4"),
            WMFSurveyViewModel.OptionViewModel(text: veryUnsatisfied, apiIdentifer: "5")
        ]

        let surveyView = WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single), cancelAction: { [weak self] in

            self?.navigationController.dismiss(animated: true, completion: { [weak self] in
                guard self != nil else { return }
            })
            DonateFunnel.shared.logYearInReviewSurveyDidTapCancel()
        }, submitAction: { [weak self] options, otherText in
            DonateFunnel.shared.logYearInReviewSurveyDidSubmit(selected: options, other: otherText)
            self?.navigationController.dismiss(animated: true, completion: { [weak self] in

                guard self != nil else { return }

                let image = UIImage(systemName: "checkmark.circle.fill")
                WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.feedbackSurveyToastTitle, subtitle: nil, image: image, type: .custom, customTypeName: "feedback-submitted", dismissPreviousAlerts: true)
                DonateFunnel.shared.logYearinReviewSurveySubmitSuccessToast()
            })
        })

        let hostedView = WMFComponentHostingController(rootView: surveyView)
        return hostedView
    }
}

extension YearInReviewCoordinator: WMFYearInReviewLoggingDelegate {

    func logYearInReviewSlideDidAppear(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewSlideImpression(slideLoggingID: slideLoggingID)
    }

    func logYearInReviewDidTapDone(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapDone(slideLoggingID: slideLoggingID)
    }

    func logYearInReviewDidTapDonate(slideLoggingID: String) {
        if let metricsID = DonateCoordinator.metricsID(for: .yearInReview(slideLoggingID: slideLoggingID), languageCode: dataStore.languageLinkController.appLanguage?.languageCode) {
            DonateFunnel.shared.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID, metricsID: metricsID)
        }
    }

    func logYearInReviewIntroDidTapLearnMore() {
        DonateFunnel.shared.logYearInReviewDidTapIntroLearnMore(slideLoggingID: introSlideLoggingID)
    }

    func logYearInReviewDidTapNext(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapNext(slideLoggingID: slideLoggingID)
    }

    func logYearInReviewDidTapShare(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDidTapShare(slideLoggingID: slideLoggingID)
    }
}

extension YearInReviewCoordinator: UIAdaptivePresentationControllerDelegate {
    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        viewModel?.logYearInReviewDidTapDone()
        (self.navigationController as? WMFComponentNavigationController)?.turnOffForcePortrait()
    }
    
    public func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        if needsExitFromIntroToast, viewModel?.isShowingIntro ?? false {
            WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.youCanAccessYIR, subtitle: nil, buttonTitle: nil, image: nil, dismissPreviousAlerts: true)
        }
        resetFromFeatureAnnouncement()
    }
}

extension YearInReviewCoordinator: YearInReviewCoordinatorDelegate {
    func handleYearInReviewAction(_ action: WMFComponents.YearInReviewCoordinatorAction) {
        switch action {
        case .tappedIntroV3GetStartedWhileLoggedOut:
            tappedIntroV3GetStartedWhileLoggedOut()
        case .tappedIntroV3GetStartedWhileLoggedIn:
            tappedIntroV3GetStartedWhileLoggedIn()
        case .tappedIntroV3DoneWhileLoggedOut:
            showExitToastFromIntroV3Done()
        case .donate(let getSourceRect, let slideLoggingID):
            
            let donateSuccessAction: () -> Void = { [weak self] in
                self?.viewModel?.donateDidSucceed()
            }
            
            let donateCoordinator = DonateCoordinator(navigationController: navigationController, source: .yearInReview(slideLoggingID: slideLoggingID), dataStore: dataStore, theme: theme, navigationStyle: .present, setLoadingBlock: {  [weak self] loading in
                guard let self,
                      let viewModel = self.viewModel else {
                    return
                }

                viewModel.isLoadingDonate = loading
            }, getDonateButtonGlobalRect: getSourceRect, donateSuccessAction: donateSuccessAction)

            self.donateCoordinator = donateCoordinator
            donateCoordinator.start()

        case .share(let image):
            guard let viewModel else { return }
            let contentProvider = YiRShareActivityContentProvider(text: viewModel.localizedStrings.shareText, appStoreURL: viewModel.shareLink, hashtag: viewModel.hashtag)
            let imageProvider = ShareAFactActivityImageItemProvider(image: image)

            let activityItems: [Any] = [contentProvider, imageProvider]

            let activityController = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
            activityController.excludedActivityTypes = [.print, .assignToContact, .addToReadingList]

            if let visibleVC = self.navigationController.visibleViewController {
                if let popover = activityController.popoverPresentationController {
                    popover.sourceRect = visibleVC.view.bounds
                    popover.sourceView = visibleVC.view
                    popover.permittedArrowDirections = []
                }

                visibleVC.present(activityController, animated: true, completion: nil)
            }
        case .dismiss(let hasSeenTwoSlides):
            (self.navigationController as? WMFComponentNavigationController)?.turnOffForcePortrait()
            navigationController.dismiss(animated: true, completion: { [weak self] in
                guard let self else { return }
                
                self.resetFromFeatureAnnouncement()
                guard hasSeenTwoSlides else { return }

                self.presentSurveyIfNeeded()
            })

        case .introLearnMore:

            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                return
            }

            if let url = featureURL {
                let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
                let newNavigationVC =
                WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                presentedViewController.present(newNavigationVC, animated: true)
            }

        case .learnMoreAttributedText(let url, let shouldShowDonateButton, let slideLoggingID):
            
            guard let url else {
                return
            }

            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                return
            }

            let webVC: SinglePageWebViewController

            if shouldShowDonateButton {
                let config = SinglePageWebViewController.YiRLearnMoreConfig(url: url, slideLoggingID: slideLoggingID, donateButtonTitle:  WMFLocalizedString("year-in-review-donate-now", value: "Donate now", comment: "Year in review donate now button title. Displayed on top of Learn more in-app web view."))
                webVC = SinglePageWebViewController(configType: .yirLearnMore(config), theme: theme)
            } else {
                let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            }

            let newNavigationVC =
            WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
            presentedViewController.present(newNavigationVC, animated: true)
        case .info:
            
            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping Info presentation.")
                return
            }
            
            guard let featureFAQURL = self.featureFAQURL else {
                return
            }

            let config = SinglePageWebViewController.StandardConfig(url: featureFAQURL, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            let newNavigationVC =
            WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
            presentedViewController.present(newNavigationVC, animated: true)
        }
    }
    
    private func tappedIntroV3GetStartedWhileLoggedIn() {
        
        if dataController.needsLoginExperimentAssignment() {
            do {
                _ = try dataController.assignLoginExperimentIfNeeded()
            } catch {
                
            }
        }
        
        if let assignment = dataController.getLoginExperimentAssignment() {
            DonateFunnel.shared.logYearInReviewDidTapIntroGetStarted(slideLoggingID: introSlideLoggingID, assignment: assignment)
        } else {
            DonateFunnel.shared.logYearInReviewDidTapIntroGetStarted(slideLoggingID: introSlideLoggingID, assignment: nil)
        }
        
        viewModel?.populateReportAndShowFirstSlide()
    }
    
    private func tappedIntroV3GetStartedWhileLoggedOut() {
        if dataController.needsLoginExperimentAssignment() {
            do {
                _ = try dataController.assignLoginExperimentIfNeeded()
            } catch {
                
            }
        }
        
        if let assignment = dataController.getLoginExperimentAssignment() {
            DonateFunnel.shared.logYearInReviewDidTapIntroGetStarted(slideLoggingID: introSlideLoggingID, assignment: assignment)
        } else {
            DonateFunnel.shared.logYearInReviewDidTapIntroGetStarted(slideLoggingID: introSlideLoggingID, assignment: nil)
        }
        
        if dataController.bypassLoginForPersonalizedFlow {
            viewModel?.populateReportAndShowFirstSlide()
        } else {
            showLoginPromptFromIntroV3GetStarted()
        }
    }
    
    private func showLoginPromptFromIntroV3GetStarted() {
        let title = CommonStrings.yearInReviewLoginPromptIntroTitle
        let subtitle = CommonStrings.yearInReviewLoginPromptSubtitle
        let button1Title = CommonStrings.joinLoginTitle
        let button2Title = CommonStrings.continueWithoutLoggingIn
        
        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)

        let action1 = UIAlertAction(title: button1Title, style: .default) { [weak self] action in
                    
            guard let self else { return }
            
            DonateFunnel.shared.logYearInReviewLoginPromptDidTapLogin(slideLoggingID: self.introSlideLoggingID)
            LoginFunnel.shared.logLoginStartFromYearInReview()
            
            let loginCoordinator = LoginCoordinator(navigationController: self.navigationController, theme: self.theme, loggingCategory: .yir)
            loginCoordinator.loginSuccessCompletion = { [weak self] in
                guard let self else { return }
                if let loginVC = self.navigationController.presentedViewController?.presentedViewController {
                    loginVC.dismiss(animated: true) { [weak self] in
                        guard let viewModel = self?.viewModel else { return }
                        viewModel.completedLoginFromIntroV3LoginPrompt()
                    }
                }
            }
            
            loginCoordinator.createAccountSuccessCustomDismissBlock = {
                if let createAccountVC = self.navigationController.presentedViewController?.presentedViewController {
                    createAccountVC.dismiss(animated: true) { [weak self] in
                        guard let viewModel = self?.viewModel else { return }
                        viewModel.completedLoginFromIntroV3LoginPrompt()
                    }
                }
            }

            loginCoordinator.start()
        }
        
        let action2 = UIAlertAction(title: button2Title, style: .default) { [weak self] action in
            guard let self else { return }
            guard let viewModel = self.viewModel else { return }
            
            DonateFunnel.shared.logYearInReviewLoginPromptDidTapContinue(slideLoggingID: self.introSlideLoggingID)
            viewModel.tappedIntroV3LoginPromptNoThanks()
        }
        
        if let presentedViewController = navigationController.presentedViewController {
            alert.addAction(action1)
            alert.addAction(action2)
            
            presentedViewController.present(alert, animated: true)
        }
    }
    
    private func showExitToastFromIntroV3Done() {
        if navigationController.presentedViewController != nil {
            navigationController.dismiss(animated: true) { [weak self] in
                guard let self else { return }
                if needsExitFromIntroToast {
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.youCanAccessYIR, subtitle: nil, buttonTitle: nil, image: nil, dismissPreviousAlerts: true)
                }
                resetFromFeatureAnnouncement()
            }
        }
    }
}


class YiRShareActivityContentProvider: UIActivityItemProvider, @unchecked Sendable {
    let text: String
    let appStoreURL: String
    let hashtag: String

    required init(text: String, appStoreURL: String, hashtag: String) {
        self.text = text
        self.appStoreURL = appStoreURL
        self.hashtag = hashtag
        super.init(placeholderItem: YiRShareActivityContentProvider.messageRepresentation(text: text, appStoreURL: appStoreURL, hashtag: hashtag))
    }

    override var item: Any {
        return  YiRShareActivityContentProvider.messageRepresentation(text: text, appStoreURL: appStoreURL, hashtag: hashtag)
    }
    
    override func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        switch activityType {
        case .postToFacebook:
            return nil
        default:
            if let activityType,
               activityType.rawValue.contains("instagram") {
                return nil
            }
            
            return item
        }
    }

    override func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return hashtag
    }

    static func messageRepresentation(text: String, appStoreURL: String, hashtag: String) -> String {
        return "\(text) (\(appStoreURL)) \(hashtag)"
    }
}
