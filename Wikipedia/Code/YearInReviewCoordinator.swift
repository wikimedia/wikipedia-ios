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

    // Collective base numbers that will change for header
    var collectiveNumArticlesNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(63590000)
        return formatter.string(from: number) ?? "63,590,000"
    }

    var collectiveNumReadingLists: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(62200000)
        return formatter.string(from: number) ?? "62,200,000"
    }

    var collectiveNumEditsNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(555647)
        return formatter.string(from: number) ?? "555,647"
    }

    var collectiveNumEditsPerMinuteNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(342)
        return formatter.string(from: number) ?? "342"
    }

    var collectiveNumViewsNumber: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(1800000000)
        return formatter.string(from: number) ?? "1,800,000,000"
    }

    var languageCode: String? {
        dataStore.languageLinkController.appLanguage?.languageCode
    }

    var aboutWikimediaURL: String {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = "\(primaryAppLanguageCode)"
        }
        return "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/About_the_Wikimedia_Foundation?uselang=\(languageCodeSuffix)"
    }

    var aboutYIRURL: URL? {
        var languageCodeSuffix = ""
        if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
            languageCodeSuffix = "\(primaryAppLanguageCode)"
        }
        return URL(string: "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/Team/iOS/Personalized_Wikipedia_Year_in_Review/How_your_data_is_used?uselang=\(languageCodeSuffix)")
    }
    
    var topReadBlogPost: String { "https://wikimediafoundation.org/news/2024/12/03/announcing-english-wikipedias-most-popular-articles-of-2024/" }
    
    private var localizedStrings: WMFYearInReviewViewModel.LocalizedStrings {
        return WMFYearInReviewViewModel.LocalizedStrings.init(
            donateButtonTitle: CommonStrings.donateTitle,
            doneButtonTitle: CommonStrings.doneTitle,
            shareButtonTitle: CommonStrings.shortShareTitle,
            nextButtonTitle: CommonStrings.nextTitle,
            finishButtonTitle: WMFLocalizedString("year-in-review-finish", value: "Finish", comment: "Year in review finish button. Displayed on last slide and dismisses feature view."),
            firstSlideTitle: dataStore.authenticationManager.authStateIsPermanent ? CommonStrings.exploreYIRTitlePersonalized : CommonStrings.exploreYiRTitle,
            firstSlideSubtitle: dataStore.authenticationManager.authStateIsPermanent ? CommonStrings.exploreYIRBodyPersonalized : CommonStrings.exploreYIRBody,
            firstSlideCTA: CommonStrings.getStartedTitle,
            firstSlideLearnMore: CommonStrings.learnMoreTitle(),
            shareText: WMFLocalizedString("year-in-review-share-text", value: "Here's my Wikipedia Year In Review. Created with the Wikipedia iOS app", comment: "Text shared the Year In Review slides"),
            wIconAccessibilityLabel: WMFLocalizedString("year-in-review-wikipedia-w-accessibility-label", value: "Wikipedia w logo", comment: "Accessibility label for the Wikipedia w logo"),
            wmfLogoImageAccessibilityLabel: WMFLocalizedString("year-in-review-wmf-logo-accessibility-label", value: "Wikimedia Foundation logo", comment: "Accessibility label for the Wikimedia Foundation logo"),
            personalizedExploreAccessibilityLabel: CommonStrings.personalizedExploreAccessibilityLabel,
            personalizedYouReadAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-you-read", value: "A puzzle piece with the Wikimedia logo walking in from the left.", comment: "Accessibility description for the personalized 'You Read' slide."),
            personalizedUserEditsAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-user-edits", value: "An animated illustration showing bytes stacking on top of each other, symbolizing the continuous creation of free knowledge.", comment: "Accessibility description for the personalized user edits slide."),
            personalizedDonationThankYouAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-donation-thank-you", value: "Wikimedia logo", comment: "Accessibility description for the personalized donation thank you slide."),
            personalizedSavedArticlesAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-saved-articles", value: "Illustration of a puzzle piece wearing a hardhat with computer screens in the back.", comment: "Accessibility description for the personalized saved articles slide."),
            personalizedWeekdayAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-weekday", value: "A clock ticking, symbolizing the time spent by people reading Wikipedia.", comment: "Accessibility description for the personalized weekday slide."),
            personalizedYourEditsViewsAccessibilityLabel: WMFLocalizedString("year-in-review-personalized-your-edits-views", value: "An illustration featuring a Wikipedia puzzle piece alongside a pen.", comment: "Accessibility description for the personalized 'Your Edits Views' slide."),
            collectiveExploreAccessibilityLabel: CommonStrings.collectiveExploreAccessibilityLabel,
            collectiveLanguagesAccessibilityLabel: WMFLocalizedString("year-in-review-collective-languages", value: "An animated illustration of a stone engraved with inscriptions representing various languages, symbolizing how Wikipedia collaboratively builds knowledge from diverse cultures and regions.", comment: "Accessibility description for the collective languages slide."),
            collectiveArticleViewsAccessibilityLabel: WMFLocalizedString("year-in-review-collective-article-views", value: "An animated illustration of a computer screen with a web browser open, actively navigating through a Wikipedia article.", comment: "Accessibility description for the collective article views slide."),
            collectiveSavedArticlesAccessibilityLabel: WMFLocalizedString("year-in-review-collective-saved-articles", value: "A puzzle globe featuring Wikipedia's logo, representing global collaboration.", comment: "Accessibility description for the collective saved articles slide."),
            collectiveAmountEditsAccessibilityLabel: WMFLocalizedString("year-in-review-collective-edits", value: "An illustration of two Wikipedia puzzle pieces, each carrying a piece of information.", comment: "Accessibility description for the collective edits slide."),
            englishEditsAccessibilityLabel: WMFLocalizedString("year-in-review-english-edits", value: "A graph showing the top 10 most edited Wikipedia language editions in 2024: English with over 31 million edits, German with 5,508,570 edits, French with 5,276,385 edits, Spanish with 4,786,205 edits, Russian with 3,303,066 edits, Italian with 3,200,398 edits, Japanese with 2,973,657 edits, Chinese with 2,505,032 edits, Polish with 1,383,808 edits, and Ukrainian with 1,376,980 edits. The total number of edits across all Wikipedia editions in 2024 is 81,987,181.", comment: "Accessibility description for the collective edits slide."),
            collectiveEditsPerMinuteAccessibilityLabel: WMFLocalizedString("year-in-review-collective-edits-per-minute", value: "A clock ticking, symbolizing the time spent by people reading Wikipedia.", comment: "Accessibility description for the collective edits per minute slide."),
            collectiveZeroAdsAccessibilityLabel: WMFLocalizedString("year-in-review-collective-zero-ads", value: "Wikimedia logo", comment: "Accessibility description for the collective zero ads slide.")
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
        let format = WMFLocalizedString("year-in-review-base-reading-title", value: "Wikipedia was available in more than 300 languages", comment: "Year in review, collective reading article count slide title, %1$@ is replaced with the number of languages available on Wikipedia, e.g. \"300\"")
        
        let numLanguagesString = formatNumber(300, fractionDigits: 0)
        return String.localizedStringWithFormat(format, numLanguagesString)
    }

    var collectiveLanguagesSlideSubtitle: String {
        let format = WMFLocalizedString("year-in-review-base-reading-subtitle", value: "Wikipedia had more than %1$@ million articles across over %2$@ active languages. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review, collective reading count slide subtitle. %1$@ is replaced with a formatted number of articles available across Wikipedia, e.g. \"63\". %2$@ is replaced with the number of active languages available on Wikipedia, e.g. \"300\"")

        let numArticlesString = formatNumber(63, fractionDigits: 0)
        let numLanguagesString = formatNumber(300, fractionDigits: 0)

        return String.localizedStringWithFormat(format, numArticlesString, numLanguagesString)
    }

    var collectiveArticleViewsSlideTitle: String {
        let format = WMFLocalizedString("year-in-review-base-viewed-title", value: "We have viewed Wikipedia articles %1$@ Billion times", comment: "Year in review, collective article view count slide title. %1$@ is replaced with the text representing the number of article views across Wikipedia, e.g. \"1.8\".")

        let numArticleViewsString = formatNumber(1.8, fractionDigits: 2)

        return String.localizedStringWithFormat(format, numArticleViewsString)
    }

    var collectiveArticleViewsSlideSubtitle: String {
        let format = WMFLocalizedString("year-in-review-base-viewed-subtitle", value: "iOS app users have viewed Wikipedia articles %1$@ Billion times. For people around the world, Wikipedia is the first stop when answering a question, looking up information for school or work, or learning a new fact.", comment: "Year in review, collective article view count subtitle, %1$@ is replaced with the number of article views text, e.g. \"1.8\"")

        let numArticleViewsString = formatNumber(1.8, fractionDigits: 2)

        return String.localizedStringWithFormat(format, numArticleViewsString)
    }

    var collectiveSavedArticlesSlideTitle: String {
        let format = WMFLocalizedString("year-in-review-base-saved-title", value: "We had over %1$@ Million reading lists", comment: "Year in review, collective saved articles count slide title, %1$@ is replaced with the number of saved articles text, e.g. \"62.6\".")

        let numSavedArticlesString = formatNumber(62.2, fractionDigits: 2)
        return String.localizedStringWithFormat(format, numSavedArticlesString)
    }

    var collectiveSavedArticlesSlideSubtitle: String {
        let format = WMFLocalizedString("year-in-review-base-saved-subtitle", value: "Active iOS App users had over 62.2 million reading lists. Adding articles to reading lists allows you to access articles even while offline. You can also log in to sync reading lists across devices.", comment: "Year in review, collective saved articles count slide subtitle")
        return String.localizedStringWithFormat(format)
    }

    var collectiveAmountEditsSlideTitle: String {
        let format = WMFLocalizedString("year-in-review-base-editors-title", value: "Editors on the iOS app made more than %1$@ edits", comment: "Year in review, collective edits count slide title, %1$@ is replaced with the number of edits text, e.g. \"555,647\".")

        let numEditsString = formatNumber(555647, fractionDigits: 0)

        return String.localizedStringWithFormat(format, numEditsString)
    }

    var collectiveAmountEditsSlideSubtitle: String {
        let format = WMFLocalizedString("year-in-review-base-editors-subtitle", value: "Wikipedia's community of volunteer editors made more than 555,647 edits on the iOS app. The heart and soul of Wikipedia is our global community of volunteer contributors, donors, and billions of readers like yourself – all united to share unlimited access to reliable information.", comment: "Year in review, collective edits count slide subtitle.")

        let numEditsString = formatNumber(555647, fractionDigits: 0)

        return String.localizedStringWithFormat(format, numEditsString)
    }

    var collectiveEditsPerMinuteSlideTitle: String {
        let format = WMFLocalizedString("year-in-review-base-edits-title", value: "Wikipedia was edited %1$@ times per minute", comment: "Year in review, collective edits per minute slide title, %1$@ is replaced with the number of edits per minute text, e.g. \"342\".")

        let numEditsPerMinString = formatNumber(342, fractionDigits: 0)

        return String.localizedStringWithFormat(format, numEditsPerMinString)
    }

    var collectiveEditsPerMinuteSlideSubtitle: String {
        let format = WMFLocalizedString("year-in-review-base-edits-subtitle", value: "Wikipedia was edited at an average rate of %1$@ times per minute. Articles are collaboratively created and improved using reliable sources. All of us have knowledge to share, [learn how to participate](%2$@).", comment: "Year in review, collective edits per minute slide subtitle, %1$@ is replaced with the number of edits per minute text, e.g. \"342\". %2$@ is replaced with a link to the Mediawiki Apps team FAQ about editing.")
        let numEditsPerMinString = formatNumber(342, fractionDigits: 0)
        var editingFAQ: String
        if languageCode == "es" {
            editingFAQ = "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ/es#Edici%C3%B3n"
        } else {
            editingFAQ = "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/iOS_FAQ#Editing"
        }
        return String.localizedStringWithFormat(format, numEditsPerMinString, editingFAQ)
    }

    var collectiveZeroAdsSlideTitle: String {
        return WMFLocalizedString("year-in-review-base-donate-title", value: "0 ads served on Wikipedia", comment: "Year in review, donate slide title when user has not made any donations that year.")
    }

    func collectiveZeroAdsSlideSubtitle() -> String {
        let format = WMFLocalizedString("year-in-review-base-donate-subtitle", value: "With your help, the Wikimedia Foundation—the nonprofit behind Wikipedia—will continue to ensure that the information you rely on is ad-free and trustworthy, while keeping Wikipedia running smoothly with cutting-edge tools and technologies. Please consider making a donation today. [Learn more about our work](%1$@).", comment: "Year in review, donate slide subtitle when user has not made any donations that year. %1$@ is replaced with a MediaWiki url with more information about WMF. Do not alter markdown when translating.")
        return String.localizedStringWithFormat(format, aboutWikimediaURL)
    }
    
    // MARK: - English Slide Strings
    var englishReadingSlideTitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-reading-slide-title",
            value: "We spent 2.9 billion hours reading",
            comment: "Reading slide title for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishReadingSlideSubtitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-reading-slide-subtitle",
            value: "People spent an estimated 2.9 billion hours—over 331,000 years!—reading English Wikipedia in 2024. Wikipedia is there when you want to learn about our changing world, win a bet among friends, or answer a curious child’s question.",
            comment: "Reading slide subtitle for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }
    
    var englishTopReadSlideTitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-top-read-slide-title",
            value: "English Wikipedia’s most popular articles",
            comment: "Top read slide title for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishTopReadSlideSubtitle: String {
        // Individual top read items
        let item1 = "Deaths in 2024"
        let item2 = "2024 United States presidential election"
        let item3 = "Kamala Harris"
        let item4 = "Donald Trump"
        let item5 = "Lyle and Erik Menendez"
        
        let linkOpening = "<a href=\"\(topReadBlogPost)\">"
        let linkClosing = "</a>"
        
        let format = WMFLocalizedString(
            "microsite-yir-english-top-read-slide-subtitle",
            value: "The top 5 visited articles on English Wikipedia were:\n\n1. %1$@\n2. %2$@\n3. %3$@\n4. %4$@\n5. %5$@\nRead more in %6$@our dedicated blog post%7$@.",
            comment: "Top read slide subtitle for English Year in Review. %1$@ %2$@ %3$@ %4$@ %5$@ are replaced with article titles, %6$@ and %7$@ wrap the blog post link."
        )
        
        return String.localizedStringWithFormat(format, item1, item2, item3, item4, item5, linkOpening, linkClosing)
    }

    var englishSavedReadingSlideTitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-saved-reading-slide-title",
            value: "We had over 62.2 million reading lists",
            comment: "Saved reading slide title for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishSavedReadingSlideSubtitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-saved-reading-slide-subtitle",
            value: "Active iOS App users had over 62.2 million reading lists. Adding articles to reading lists allows you to access articles even while offline. You can also log in to sync reading lists across devices.",
            comment: "Saved reading slide subtitle for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }
    
    var englishEditsSlideTitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-edits-slide-title",
            value: "Editors made 98 million changes this year",
            comment: "Edits slide title for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishEditsSlideSubtitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-edits-slide-subtitle",
            value: "Volunteers made 98,222,407 changes across over 300 different language editions of Wikipedia. Over 37 million changes were made on English Wikipedia. Every hour of every day, volunteers are working to improve Wikipedia.",
            comment: "Edits slide subtitle for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishEditsBytesSlideTitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-edits-bytes-slide-title",
            value: "4 billion bytes added",
            comment: "Edits bytes slide title for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishEditsBytesSlideSubtitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-edits-bytes-slide-subtitle",
            value: "In 2024, volunteers added 4,104,852,969 bytes to English Wikipedia. The sum of all their work together leads to a steadily improving, fact-based, and reliable knowledge resource that they give to the world. All of us have knowledge to share, [learn how to participate](%1$@).",
            comment: "Edits bytes slide subtitle for English Year in Review, %1$@ is replaced by link to learn to participate."
        )
        var editingFAQ: String
        if languageCode == "es" {
            editingFAQ = "https://www.mediawiki.org/wiki/Wikimedia_Apps/iOS_FAQ/es#Edici%C3%B3n"
        } else {
            editingFAQ = "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/iOS_FAQ#Editing"
        }
        return String.localizedStringWithFormat(format, editingFAQ)
    }
    
    var englishNonDonorSlideTitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-non-donor-slide-title",
            value: "0 ads served on Wikipedia",
            comment: "Non-donor slide title for English Year in Review."
        )
        return String.localizedStringWithFormat(format)
    }

    var englishNonDonorSlideSubitle: String {
        let format = WMFLocalizedString(
            "microsite-yir-english-non-donor-slide-subtitle",
            value: "With your help, the Wikimedia Foundation—the nonprofit behind Wikipedia—will continue to ensure that the information you rely on is ad-free and trustworthy, while keeping Wikipedia running smoothly with cutting-edge tools and technologies. Please consider making a donation today. [Learn more about our work](%1$@).",
            comment: "Non-donor slide subtitle for English Year in Review with a link to learn more about Wikimedia's work. %1$@ is replaced by the link."
        )
        return String.localizedStringWithFormat(format, aboutWikimediaURL)
    }
    
    // MARK: - Personalized Slide Strings

    func personalizedYouReadSlideTitle(readCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-reading-title-format", value: "You read {{PLURAL:%1$d|%1$d article|%1$d articles}}", comment: "Year in review, personalized reading article count slide title for users that read articles. %1$d is replaced with the number of articles the user read.")
        return String.localizedStringWithFormat(format, readCount)
    }

    func personalizedYouReadSlideSubtitle(readCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-reading-subtitle-format", value: "You read {{PLURAL:%1$d|%1$d article|%1$d articles}}. Wikipedia had %2$@ million articles available across over %3$@ active languages. You joined millions in expanding knowledge and exploring diverse topics.", comment: "Year in review, personalized reading article count slide subtitle for users that read articles. %1$d is replaced with the number of articles the user read. %2$@ is replaced with the number of articles available across Wikipedia, for example, \"63.59\". %3$@ is replaced with the number of active languages available on Wikipedia, for example \"300\"")

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let numArticles = NSNumber(63)
        let numArticlesString = formatter.string(from: numArticles) ?? "63"

        formatter.maximumFractionDigits = 0
        let numLanguages = NSNumber(300)
        let numLanguagesString = formatter.string(from: numLanguages) ?? "300"

        return String.localizedStringWithFormat(format, readCount, numArticlesString, numLanguagesString)
    }

    func personalizedSlide1Overlay(readCount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: readCount)
        return formatter.string(from: number) ?? String(readCount)
    }
    
    func personalizedDaySlideTitle(day: Int) -> String {
        let format = WMFLocalizedString(
            "year-in-review-personalized-day-title-format",
            value: "You read most on %1$@.",
            comment: "Year in review, personalized slide title for users that displays the weekday they read most. %1$@ is replaced with the weekday."
        )
        
        return String.localizedStringWithFormat(format, getLocalizedDay(day: day))
    }
    
    func personalizedDaySlideSubtitle(day: Int) -> String {
        let format = WMFLocalizedString(
            "year-in-review-personalized-day-subtitle-format",
            value: "You read the most articles on %1$@. It's clear that %1$@ are your prime day for exploring new content. Thanks for making the most of your reading time!",
            comment: "Year in review, personalized slide subtitle for users that displays the weekday they read most. %1$@ is replaced with the weekday."
        )
        return String.localizedStringWithFormat(format, getLocalizedDay(day: day))
    }
    
    func personalizedSaveCountSlideOverlay(saveCount: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: saveCount)
        return formatter.string(from: number) ?? String(saveCount)
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
        let format = WMFLocalizedString("year-in-review-personalized-editing-title-format", value: "You edited Wikipedia {{PLURAL:%1$d|%1$d time|%1$d times}}", comment: "Year in review, personalized editing article count slide title for users that edited articles. %1$d is replaced with the number of edits the user made.")
        return String.localizedStringWithFormat(format, editCount)
    }

    func personzlizedUserEditsSlideTitle500Plus() -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-title-format-500plus", value: "You edited Wikipedia 500+ times", comment: "Year in review, personalized editing article count slide title for users that edited articles 500+ times.")
        return String.localizedStringWithFormat(format)
    }

    func personzlizedUserEditsSlideSubtitle(editCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-subtitle-format", value: "You edited Wikipedia {{PLURAL:%1$d|%1$d time|%1$d times}}. Thank you for being one of the volunteer editors making a difference on Wikimedia projects around the world.", comment: "Year in review, personalized editing article count slide subtitle for users that edited articles. %1$d is replaced with the number of edits the user made.")
        return String.localizedStringWithFormat(format, editCount)
    }

    func personzlizedUserEditsSlideSubtitle500Plus() -> String {
        let format = WMFLocalizedString("year-in-review-personalized-editing-subtitle-format-500plus", value: "You edited Wikipedia 500+ times. Thank you for being one of the volunteer editors making a difference on Wikimedia projects around the world.", comment: "Year in review, personalized editing article count slide subtitle for users that edited articles more than 500 times.")
        return String.localizedStringWithFormat(format)
    }

    func personalizedSlide3Overlay(editCount: Int) -> String {
        guard editCount < 500 else {
            return "500+"
        }

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let number = NSNumber(value: editCount)
        return formatter.string(from: number) ?? String(editCount)
    }
    
    func personalizedYourEditsViewedSlideTitle(views: Int) -> String {
        let format = WMFLocalizedString(
            "year-in-review-personalized-edit-views-title-format",
            value: "Your edits have been viewed more than %1$@ times recently",
            comment: "Year in review, personalized slide title for users that display how many views their edits have. %1$@ is replaced with the amount of edit views."
        )
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedViews = formatter.string(from: NSNumber(value: views)) ?? "\(views)"
        return String.localizedStringWithFormat(format, formattedViews)
    }
    
    func personalizedYourEditsViewedSlideSubtitle(views: Int) -> String {
        let format = WMFLocalizedString(
            "year-in-review-personalized-edit-views-subtitle-format",
            value: "Readers around the world appreciate your contributions. In the last 2 months, articles you've edited have received %1$@ total views. Thanks to editors like you, Wikipedia is a steadily improving, fact-based, and reliable knowledge resource for the world",
            comment: "Year in review, personalized slide subtitle for users that display how many views their edits have. %1$@ is replaced with the amount of edit views."
        )
        
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        let formattedViews = formatter.string(from: NSNumber(value: views)) ?? "\(views)"
        return String.localizedStringWithFormat(format, formattedViews)
    }
    
    var personalizedThankYouTitle: String {
        return WMFLocalizedString("year-in-review-personalized-donate-title", value: "Your generosity helped keep Wikipedia thriving", comment: "Year in review, personalized donate slide title for users that donated at least once that year. ")
    }

    func personalizedThankYouSubtitle(languageCode: String?) -> String {

        let urlString: String
        if let languageCode {
            urlString = "https://www.mediawiki.org/wiki/Wikimedia_Apps/About_the_Wikimedia_Foundation/\(languageCode)"
        } else {
            urlString = "https://www.mediawiki.org/wiki/Wikimedia_Apps/About_the_Wikimedia_Foundation"
        }

        let format = WMFLocalizedString("year-in-review-personalized-donate-subtitle", value: "Thank you for investing in the future of free knowledge. This year, the Wikimedia Foundation improved the technology to serve every reader and volunteer better, developed tools that empower collaboration, and supported Wikipedia in more languages. [Learn more about our work](%1$@).", comment: "Year in review, personalized donate slide subtitle for users that donated at least once that year. %1$@ is replaced with a MediaWiki url with more information about WMF. Do not alter markdown when translating.")
        return String.localizedStringWithFormat(format, urlString)
    }

    func personalizedSaveCountSlideTitle(saveCount: Int) -> String {
        let format = WMFLocalizedString("year-in-review-personalized-saved-title-format", value: "You saved {{PLURAL:%1$d|%1$d article|%1$d articles}}", comment: "Year in review, personalized saved articles slide subtitle. %1$d is replaced with the number of articles the user saved.")
        return String.localizedStringWithFormat(format, saveCount)
    }

    func personalizedSaveCountSlideSubtitle(saveCount: Int, articleNames: [String]) -> String {
        
        let articleName1 = articleNames.count >= 3 ? articleNames[0] : ""
        let articleName2 = articleNames.count >= 3 ? articleNames[1] : ""
        let articleName3 = articleNames.count >= 3 ? articleNames[2] : ""
        
        let format = WMFLocalizedString("year-in-review-personalized-saved-subtitle-format", value: "You saved {{PLURAL:%1$d|%1$d article|%1$d articles}} this year, including %2$@, %3$@ and %4$@. Each saved article reflects your interests and helps build a personalized knowledge base on Wikipedia.", comment: "Year in review, personalized saved articles slide subtitle. %1$D is replaced with the number of articles the user saved, %2$@, %3$@ and %4$@ are replaced with the names  three random articles the user saved.")
        return String.localizedStringWithFormat(format, saveCount, articleName1, articleName2, articleName3)
    }

    // MARK: - Funcs

    private struct PersonalizedSlides {
        let readCount: YearInReviewSlideContent?
        let editCount: YearInReviewSlideContent?
        let donateCount: YearInReviewSlideContent?
        let saveCount: YearInReviewSlideContent?
        let mostReadDay: YearInReviewSlideContent?
        let viewCount: YearInReviewSlideContent?
    }

    func shoudlHideDonateButton() -> Bool {
        guard let dataController = try? WMFYearInReviewDataController() else {
            return false
        }
        return dataController.shouldHideDonateButton()
    }

    private func getPersonalizedSlides() -> PersonalizedSlides {

        guard let dataController = try? WMFYearInReviewDataController(),
              let report = try? dataController.fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear) else {
            return PersonalizedSlides(readCount: nil, editCount: nil, donateCount: nil, saveCount: nil, mostReadDay: nil, viewCount: nil)
        }

        var readCountSlide: YearInReviewSlideContent? = nil
        var editCountSlide: YearInReviewSlideContent? = nil
        var donateCountSlide: YearInReviewSlideContent? = nil
        var saveCountSlide: YearInReviewSlideContent? = nil
        var mostReadDaySlide: YearInReviewSlideContent? = nil
        var viewCountSlide: YearInReviewSlideContent? = nil
        
        for slide in report.slides {
            switch slide.id {
            case .readCount:
                if let data = slide.data {
                    let decoder = JSONDecoder()
                    if let readCount = try? decoder.decode(Int.self, from: data),
                       readCount > 5 {
                        readCountSlide = YearInReviewSlideContent(
                            gifName: "personal-slide-01",
                            altText: localizedStrings.personalizedYouReadAccessibilityLabel,
                            title: personalizedYouReadSlideTitle(readCount: readCount),
                            informationBubbleText: nil,
                            subtitle: personalizedYouReadSlideSubtitle(readCount: readCount),
                            loggingID: "read_count_custom",
                            infoURL: aboutYIRURL,
                            hideDonateButton: shoudlHideDonateButton())
                    }
                }
            case .editCount:
                if let data = slide.data {
                    let decoder = JSONDecoder()
                    if let editCount = try? decoder.decode(Int.self, from: data),
                       editCount > 0 {
                        editCountSlide = YearInReviewSlideContent(
                            gifName: "personal-slide-04",
                            altText: localizedStrings.personalizedUserEditsAccessibilityLabel,
                            title: editCount >= 500 ? personzlizedUserEditsSlideTitle500Plus() : personzlizedUserEditsSlideTitle(editCount: editCount),
                            informationBubbleText: nil,
                            subtitle: editCount >= 500 ? personzlizedUserEditsSlideSubtitle500Plus() : personzlizedUserEditsSlideSubtitle(editCount: editCount),
                            loggingID: "edit_count_custom",
                            infoURL: aboutYIRURL,
                            hideDonateButton: shoudlHideDonateButton())
                    }
                }
            case .donateCount:
                if let data = slide.data {
                    let decoder = JSONDecoder()
                    if let donateCount = try? decoder.decode(Int.self, from: data),
                       donateCount > 0 {
                        donateCountSlide = YearInReviewSlideContent(
                            gifName: "all-slide-06",
                            altText: localizedStrings.personalizedDonationThankYouAccessibilityLabel,
                            title: personalizedThankYouTitle,
                            informationBubbleText: nil,
                            subtitle: personalizedThankYouSubtitle(languageCode: dataStore.languageLinkController.appLanguage?.languageCode),
                            loggingID: "thank_custom",
                            infoURL: aboutYIRURL,
                            hideDonateButton: true)
                    }
                }
            case .saveCount:
                if let data = slide.data {
                    let decoder = JSONDecoder()
                    if let savedSlideData = try? decoder.decode(SavedArticleSlideData.self, from: data),
                       savedSlideData.savedArticlesCount > 3,
                       savedSlideData.articleTitles.count >= 3 {
                        let count = savedSlideData.savedArticlesCount
                        saveCountSlide = YearInReviewSlideContent(
                            gifName: "personal-slide-03",
                            altText: localizedStrings.personalizedSavedArticlesAccessibilityLabel,
                            title: personalizedSaveCountSlideTitle(saveCount: count),
                            informationBubbleText: nil,
                            subtitle: personalizedSaveCountSlideSubtitle(saveCount: count, articleNames: savedSlideData.articleTitles),
                            loggingID: "save_count_custom",
                            infoURL: aboutYIRURL,
                            hideDonateButton: shoudlHideDonateButton())
                    }
                }
            case .mostReadDay:
                if let data = slide.data {
                    let decoder = JSONDecoder()
                    if let mostReadDay = try? decoder.decode(WMFPageViewDay.self, from: data),
                       mostReadDay.getViewCount() > 0 {
                        mostReadDaySlide = YearInReviewSlideContent(
                            gifName: "personal-slide-02",
                            altText: localizedStrings.personalizedWeekdayAccessibilityLabel,
                            title: personalizedDaySlideTitle(day: mostReadDay.getDay()),
                            informationBubbleText: nil,
                            subtitle: personalizedDaySlideSubtitle(day: mostReadDay.getDay()),
                            loggingID: "read_day_custom",
                            infoURL: aboutYIRURL,
                            hideDonateButton: shoudlHideDonateButton())
                    }
                }
            case .viewCount:
                if let data = slide.data {
                    let decoder = JSONDecoder()
                    if let viewCount = try? decoder.decode(Int.self, from: data),
                       viewCount > 0 {
                        viewCountSlide = YearInReviewSlideContent(
                            gifName: "personal-slide-05",
                            altText: localizedStrings.personalizedYourEditsViewsAccessibilityLabel,
                            title: personalizedYourEditsViewedSlideTitle(views: viewCount),
                            informationBubbleText: nil,
                            subtitle: personalizedYourEditsViewedSlideSubtitle(views: viewCount),
                            loggingID: "edit_view_count_custom",
                            infoURL: aboutYIRURL,
                            hideDonateButton: shoudlHideDonateButton())
                    }
                }
                break
            }
        }
        return PersonalizedSlides(readCount: readCountSlide, editCount: editCountSlide, donateCount: donateCountSlide, saveCount: saveCountSlide, mostReadDay: mostReadDaySlide, viewCount: viewCountSlide)
    }

    @discardableResult
    func start() -> Bool {
        let collectiveLanguagesSlide = YearInReviewSlideContent(
           gifName: "non-english-slide-01",
           altText: localizedStrings.collectiveLanguagesAccessibilityLabel,
           title: collectiveLanguagesSlideTitle,
           informationBubbleText: nil,
           subtitle: collectiveLanguagesSlideSubtitle,
           loggingID: "read_count_base",
           infoURL: aboutYIRURL,
           hideDonateButton: shoudlHideDonateButton())

        let collectiveArticleViewsSlide = YearInReviewSlideContent(
            gifName: "english-slide-02",
            altText: localizedStrings.collectiveArticleViewsAccessibilityLabel,
            title: collectiveArticleViewsSlideTitle,
            informationBubbleText: nil,
            subtitle: collectiveArticleViewsSlideSubtitle,
            loggingID: "read_view_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())

        let collectiveSavedArticlesSlide = YearInReviewSlideContent(
            gifName: "english-slide-03",
            altText: localizedStrings.collectiveSavedArticlesAccessibilityLabel,
            title: collectiveSavedArticlesSlideTitle,
            informationBubbleText: nil,
            subtitle: collectiveSavedArticlesSlideSubtitle,
            loggingID: "list_count_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())

        let collectiveAmountEditsSlide = YearInReviewSlideContent(
           gifName: "non-english-slide-04",
           altText: localizedStrings.collectiveAmountEditsAccessibilityLabel,
           title: collectiveAmountEditsSlideTitle,
           informationBubbleText: nil,
           subtitle: collectiveAmountEditsSlideSubtitle,
           loggingID: "edit_count_base",
           infoURL: aboutYIRURL,
           hideDonateButton: shoudlHideDonateButton())
        
        let collectiveEditsPerMinuteSlide = YearInReviewSlideContent(
            gifName: "english-slide-01",
            altText: localizedStrings.collectiveEditsPerMinuteAccessibilityLabel,
            title: collectiveEditsPerMinuteSlideTitle,
            informationBubbleText: nil,
            subtitle: collectiveEditsPerMinuteSlideSubtitle,
            loggingID: "edit_rate_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        let collectiveZeroAdsSlide = YearInReviewSlideContent(
            gifName: "all-slide-06",
            altText: localizedStrings.collectiveZeroAdsAccessibilityLabel,
            title: collectiveZeroAdsSlideTitle,
            informationBubbleText: nil,
            subtitle: collectiveZeroAdsSlideSubtitle(),
            loggingID: "ads_served_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        // MARK: - English Slides
        
        let englishHoursReadingSlide = YearInReviewSlideContent(
            gifName: "english-slide-01",
            altText: localizedStrings.collectiveEditsPerMinuteAccessibilityLabel,
            title: englishReadingSlideTitle,
            informationBubbleText: nil,
            subtitle: englishReadingSlideSubtitle,
            loggingID: "en_read_hours_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        let englishTopReadSlide = YearInReviewSlideContent(
            gifName: "english-slide-02",
            altText: localizedStrings.collectiveArticleViewsAccessibilityLabel,
            title: englishTopReadSlideTitle,
            informationBubbleText: nil,
            subtitle: englishTopReadSlideSubtitle,
            isSubtitleAttributedString: true,
            loggingID: "en_most_visit_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        let englishReadingListSlide = YearInReviewSlideContent(
            gifName: "english-slide-03",
            altText: localizedStrings.collectiveSavedArticlesAccessibilityLabel,
            title: englishSavedReadingSlideTitle,
            informationBubbleText: nil,
            subtitle: englishSavedReadingSlideSubtitle,
            loggingID: "en_list_count_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        let englishEditsSlide = YearInReviewSlideContent(
            gifName: "english-slide-04",
            altText: localizedStrings.englishEditsAccessibilityLabel,
            title: englishEditsSlideTitle,
            informationBubbleText: nil,
            subtitle: englishEditsSlideSubtitle,
            loggingID: "en_edit_count_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        let englishEditsBytesSlide = YearInReviewSlideContent(
            gifName: "english-slide-05",
            altText: localizedStrings.personalizedUserEditsAccessibilityLabel,
            title: englishEditsBytesSlideTitle,
            informationBubbleText: nil,
            subtitle: englishEditsBytesSlideSubtitle,
            loggingID: "en_byte_base",
            infoURL: aboutYIRURL,
            hideDonateButton: shoudlHideDonateButton())
        
        let personalizedSlides = getPersonalizedSlides()
        
        let finalSlides: [YearInReviewSlideContent]
        
        let isEnglish = dataStore.languageLinkController.appLanguage?.languageCode == "en"
        
        // We should only show non-donate personalized slides to logged in users.
        if dataStore.authenticationManager.authStateIsPermanent {
            finalSlides = [(personalizedSlides.readCount ?? (isEnglish ? englishHoursReadingSlide : collectiveLanguagesSlide)),
                           (personalizedSlides.mostReadDay ?? (isEnglish ? englishTopReadSlide : collectiveArticleViewsSlide)),
                           (personalizedSlides.saveCount ?? (isEnglish ? englishReadingListSlide : collectiveSavedArticlesSlide)),
                           (personalizedSlides.editCount ?? (isEnglish ? englishEditsSlide : collectiveAmountEditsSlide)),
                           (personalizedSlides.viewCount ?? (isEnglish ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide)),
                           (personalizedSlides.donateCount ?? collectiveZeroAdsSlide)]
        } else {
            finalSlides = [(isEnglish ? englishHoursReadingSlide : collectiveLanguagesSlide),
                           (isEnglish ? englishTopReadSlide : collectiveArticleViewsSlide),
                           (isEnglish ? englishReadingListSlide : collectiveSavedArticlesSlide),
                           (isEnglish ? englishEditsSlide : collectiveAmountEditsSlide),
                           (isEnglish ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide),
                           (personalizedSlides.donateCount ?? collectiveZeroAdsSlide)]
        }
        
        let appShareLink = WMFYearInReviewDataController.appShareLink
        let hashtag = "#WikipediaYearInReview"

        let viewModel = WMFYearInReviewViewModel(
            localizedStrings: localizedStrings,
            slides: finalSlides,
            shareLink: appShareLink,
            hashtag: hashtag,
            hasPersonalizedDonateSlide: personalizedSlides.donateCount != nil,
            coordinatorDelegate: self,
            loggingDelegate: self,
            badgeDelegate: badgeDelegate,
            isUserAuth: dataStore.authenticationManager.authStateIsPermanent
        )
        
        let yirview = WMFYearInReviewView(viewModel: viewModel)

        self.viewModel = viewModel
        let finalView = yirview.environmentObject(targetRects)
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

    private func presentSurveyIfNeeded() {
        if !self.dataController.hasPresentedYiRSurvey {
            let surveyVC = surveyViewController()
            navigationController.present(surveyVC, animated: true, completion: {
                DonateFunnel.shared.logYearInReviewSurveyDidAppear()
            })
            self.dataController.hasPresentedYiRSurvey = true
        }
    }

    private func needsLoginPrompt() -> Bool {
        return !dataStore.authenticationManager.authStateIsPermanent
    }

    private func presentLoginPrompt() {
        let title = WMFLocalizedString("year-in-review-login-title", value: "Improve your Year in Review", comment: "Title of alert that asks user to login. Displayed after they completed the feature for the first time.")
        let subtitle = WMFLocalizedString("year-in-review-login-subtitle", value: "Login or create an account to be eligible for more personalized insights", comment: "Subtitle of alert that asks user to login. Displayed after they completed the feature for the first time.")
        let button1Title = CommonStrings.joinLoginTitle
        let button2Title = CommonStrings.noThanksTitle

        let alert = UIAlertController(title: title, message: subtitle, preferredStyle: .alert)
        let action1 = UIAlertAction(title: button1Title, style: .default) { [weak self] action in

            guard let self else { return }

            DonateFunnel.shared.logYearInReviewLoginPromptDidTapLogin()
            let loginCoordinator = LoginCoordinator(navigationController: self.navigationController, theme: self.theme)
            
            
            loginCoordinator.loginSuccessCompletion = {
                self.navigationController.dismiss(animated: true) {
                    self.start()
                }
            }
            
            loginCoordinator.createAccountSuccessCustomDismissBlock = {
                self.navigationController.dismiss(animated: true) {
                    self.start()
                }
            }
            
            loginCoordinator.start()
        }
        let action2 = UIAlertAction(title: button2Title, style: .default) { action in
            DonateFunnel.shared.logYearInReviewLoginPromptDidTapNoThanks()
        }
        alert.addAction(action1)
        alert.addAction(action2)

        DonateFunnel.shared.logYearInReviewLoginPromptDidAppear()

        navigationController.present(alert, animated: true)
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
            WMFSurveyViewModel.OptionViewModel(text: verySatisfied, apiIdentifer: "v_satisfied"),
            WMFSurveyViewModel.OptionViewModel(text: satisfied, apiIdentifer: "satisfied"),
            WMFSurveyViewModel.OptionViewModel(text: neutral, apiIdentifer: "neutral"),
            WMFSurveyViewModel.OptionViewModel(text: unsatisfied, apiIdentifer: "unsatisfied"),
            WMFSurveyViewModel.OptionViewModel(text: veryUnsatisfied, apiIdentifer: "v_unsatisfied")
        ]

        let surveyView = WMFSurveyView(viewModel: WMFSurveyViewModel(localizedStrings: surveyLocalizedStrings, options: surveyOptions, selectionType: .single), cancelAction: { [weak self] in

            self?.navigationController.dismiss(animated: true, completion: { [weak self] in
                guard let self else { return }

                if self.needsLoginPrompt() {
                    presentLoginPrompt()
                }
            })
            DonateFunnel.shared.logYearInReviewSurveyDidTapCancel()
        }, submitAction: { [weak self] options, otherText in
            DonateFunnel.shared.logYearInReviewSurveyDidSubmit(selected: options, other: otherText)
            self?.navigationController.dismiss(animated: true, completion: { [weak self] in

                guard let self else { return }

                if self.needsLoginPrompt() {
                    presentLoginPrompt()
                } else {
                    let image = UIImage(systemName: "checkmark.circle.fill")
                    WMFAlertManager.sharedInstance.showBottomAlertWithMessage(CommonStrings.feedbackSurveyToastTitle, subtitle: nil, image: image, type: .custom, customTypeName: "feedback-submitted", dismissPreviousAlerts: true)
                    DonateFunnel.shared.logYearinReviewSurveySubmitSuccessToast()
                }
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
        if let metricsID = DonateCoordinator.metricsID(for: .yearInReview, languageCode: dataStore.languageLinkController.appLanguage?.languageCode) {
            DonateFunnel.shared.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID, metricsID: metricsID)
        }
    }

    func logYearInReviewIntroDidTapContinue() {
        DonateFunnel.shared.logYearInReviewDidTapIntroContinue(isEntryC: dataStore.authenticationManager.authStateIsPermanent)
    }

    func logYearInReviewIntroDidTapLearnMore() {
        DonateFunnel.shared.logYearInReviewDidTapIntroLearnMore(isEntryC: dataStore.authenticationManager.authStateIsPermanent)
    }

    func logYearInReviewDonateDidTapLearnMore(slideLoggingID: String) {
        DonateFunnel.shared.logYearInReviewDonateSlideDidTapLearnMoreLink(slideLoggingID: slideLoggingID)
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
}

extension YearInReviewCoordinator: YearInReviewCoordinatorDelegate {
    func handleYearInReviewAction(_ action: WMFComponents.YearInReviewCoordinatorAction) {
        switch action {
        case .donate(let rect):
            let donateCoordinator = DonateCoordinator(navigationController: navigationController, donateButtonGlobalRect: rect, source: .yearInReview, dataStore: dataStore, theme: theme, navigationStyle: .present, setLoadingBlock: {  [weak self] loading in
                guard let self,
                      let viewModel = self.viewModel else {
                    return
                }

                viewModel.isLoading = loading
            })

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

                guard hasSeenTwoSlides else { return }

                self.presentSurveyIfNeeded()
            })

        case .introLearnMore:

            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                return
            }
            var languageCodeSuffix = ""
            if let primaryAppLanguageCode = dataStore.languageLinkController.appLanguage?.languageCode {
                languageCodeSuffix = "\(primaryAppLanguageCode)"
            }
            if let url = URL(string: "https://www.mediawiki.org/wiki/Special:MyLanguage/Wikimedia_Apps/Team/iOS/Personalized_Wikipedia_Year_in_Review/How_your_data_is_used?uselang=\(languageCodeSuffix)") {
                let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
                let newNavigationVC =
                WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
                presentedViewController.present(newNavigationVC, animated: true)
            }

        case .learnMore(let url, let shouldShowDonateButton):

            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping Learn More presentation.")
                return
            }

            let webVC: SinglePageWebViewController
            let slideLoggingID: String

            if shouldShowDonateButton {
                let config = SinglePageWebViewController.YiRLearnMoreConfig(url: url, donateButtonTitle:  WMFLocalizedString("year-in-review-donate-now", value: "Donate now", comment: "Year in review donate now button title. Displayed on top of Learn more in-app web view."))
                webVC = SinglePageWebViewController(configType: .yirLearnMore(config), theme: theme)
                slideLoggingID = "about_wikimedia_base"
            } else {
                let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
                webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
                slideLoggingID = "about_wikimedia_custom"
            }

            let newNavigationVC =
            WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
            presentedViewController.present(newNavigationVC, animated: true, completion: { DonateFunnel.shared.logYearInReviewDonateSlideLearnMoreWebViewDidAppear(slideLoggingID: slideLoggingID)})
        case .info(let url):
            guard let presentedViewController = navigationController.presentedViewController else {
                DDLogError("Unexpected navigation controller state. Skipping Info presentation.")
                return
            }

            let config = SinglePageWebViewController.StandardConfig(url: url, useSimpleNavigationBar: true)
            let webVC = SinglePageWebViewController(configType: .standard(config), theme: theme)
            let newNavigationVC =
            WMFComponentNavigationController(rootViewController: webVC, modalPresentationStyle: .formSheet)
            presentedViewController.present(newNavigationVC, animated: true)
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
