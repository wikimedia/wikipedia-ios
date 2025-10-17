import Foundation
import SwiftUI
import WMFData

public protocol WMFYearInReviewLoggingDelegate: AnyObject {
    func logYearInReviewIntroDidTapContinue()
    func logYearInReviewIntroDidTapLearnMore()
    func logYearInReviewDonateDidTapLearnMore(slideLoggingID: String)
    func logYearInReviewSlideDidAppear(slideLoggingID: String)
    func logYearInReviewDidTapDone(slideLoggingID: String)
    func logYearInReviewDidTapNext(slideLoggingID: String)
    func logYearInReviewDidTapDonate(slideLoggingID: String)
    func logYearInReviewDidTapShare(slideLoggingID: String)
}

public class WMFYearInReviewViewModel: ObservableObject {
    
    public struct LocalizedStrings {
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, shareText: String, introV2Title: String, introV2TitlePersonalized: String, introV2Subtitle: String, introV2SubtitlePersonzalized: String, introV2PrimaryButtonTitle: String, introV2SecondaryButtonTitle: String, introV3Title: String, introV3Subtitle: String, introV3Footer: String, introV3PrimaryButtonTitle: String, introV3SecondaryButtonTitle: String, wIconAccessibilityLabel: String, wmfLogoImageAccessibilityLabel: String, personalizedExploreAccessibilityLabel: String, personalizedYouReadAccessibilityLabel: String, personalizedUserEditsAccessibilityLabel: String, personalizedDonationThankYouAccessibilityLabel: String, personalizedSavedArticlesAccessibilityLabel: String, personalizedWeekdayAccessibilityLabel: String, personalizedYourEditsViewsAccessibilityLabel: String, collectiveExploreAccessibilityLabel: String, collectiveLanguagesAccessibilityLabel: String, collectiveArticleViewsAccessibilityLabel: String, collectiveSavedArticlesAccessibilityLabel: String, collectiveAmountEditsAccessibilityLabel: String, englishEditsAccessibilityLabel: String, collectiveEditsPerMinuteAccessibilityLabel: String, collectiveZeroAdsAccessibilityLabel: String, englishReadingSlideTitle: String, englishReadingSlideSubtitle: String, englishTopReadSlideTitle: String, englishTopReadSlideSubtitle: String, englishSavedReadingSlideTitle: String, englishSavedReadingSlideSubtitle: String, englishEditsSlideTitle: String, englishEditsSlideSubtitle: String, englishEditsBytesSlideTitle: String, englishEditsBytesSlideSubtitle: String, collectiveLanguagesSlideTitle: String, collectiveLanguagesSlideSubtitle: String, collectiveArticleViewsSlideTitle: String, collectiveArticleViewsSlideSubtitle: String, collectiveSavedArticlesSlideTitle: String, collectiveSavedArticlesSlideSubtitle: String, collectiveAmountEditsSlideTitle: String, collectiveAmountEditsSlideSubtitle: String, collectiveEditsPerMinuteSlideTitle: String, collectiveEditsPerMinuteSlideSubtitle: String, collectiveZeroAdsSlideTitle: String, collectiveZeroAdsSlideSubtitle: @escaping () -> String, personalizedYouReadSlideTitleV2: @escaping (Int) -> String, personalizedYouReadSlideSubtitleV2: @escaping (Int) -> String, personalizedYouReadSlideTitleV3: @escaping (Int, Int) -> String, personalizedYouReadSlideSubtitleV3: @escaping (Int) -> String, personalizedDateSlideTitleV2: @escaping (Int) -> String, personalizedDateSlideSubtitleV2: @escaping (Int) -> String, personalizedDateSlideTitleV3: String, personalizedDateSlideTimeV3: @escaping (Int) -> String, personalizedDateSlideTimeFooterV3: String, personalizedDateSlideDayV3: @escaping (Int) -> String, personalizedDateSlideDayFooterV3: String, personalizedDateSlideMonthV3: @escaping (Int) -> String, personalizedDateSlideMonthFooterV3: String, personalizedSaveCountSlideTitle: @escaping (Int) -> String, personalizedSaveCountSlideSubtitle: @escaping (Int, [String]) -> String, personalizedUserEditsSlideTitle: @escaping (Int) -> String, personzlizedUserEditsSlideTitle500Plus: String, personzlizedUserEditsSlideSubtitleEN: String, personzlizedUserEditsSlideSubtitleNonEN: String, personalizedYourEditsViewedSlideTitle: @escaping (Int) -> String, personalizedYourEditsViewedSlideSubtitle: @escaping (Int) -> String, personalizedThankYouTitle: String, personalizedThankYouSubtitle: @escaping (String) -> String, personalizedMostReadCategoriesSlideTitle: String, personalizedMostReadCategoriesSlideSubtitle: @escaping ([String]) -> String, personalizedMostReadArticlesSlideTitle: String, personalizedMostReadArticlesSlideSubtitle: @escaping ([String]) -> String, personalizedLocationSlideTitle: @escaping (String) -> String, personalizedLocationSlideSubtitle: @escaping ([String]) -> String, noncontributorTitle: String, noncontributorSubtitle: String, noncontributorButtonText: String, contributorTitle: String, contributorSubtitle: @escaping (Bool, Bool) -> String, contributorGiftTitle: String, contributorGiftSubtitle: String, highlightsSlideTitle: String, highlightsSlideSubtitle: String, highlightsSlideButtonTitle: String, longestReadArticlesTitle: String, minutesReadTitle: String, favoriteReadingDayTitle: String, savedArticlesTitle: String, favoriteCategoriesTitle: String, editedArticlesTitle: String, enWikiTopArticlesTitle: String, enWikiTopArticlesValue: [String], hoursSpentReadingTitle: String, hoursSpentReadingValue: String, numberOfChangesMadeTitle: String, numberOfChangesMadeValue: String, numberOfViewedArticlesTitle: String, numberOfViewedArticlesValue: String, numberOfReadingListsTitle: String, numberOfEditsTitle: String, numberOfEditsValue: String, editFrequencyTitle: String, editFrequencyValue: String, logoCaption: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.finishButtonTitle = finishButtonTitle
            self.shareText = shareText
            self.introV2Title = introV2Title
            self.introV2TitlePersonalized = introV2TitlePersonalized
            self.introV2Subtitle = introV2Subtitle
            self.introV2SubtitlePersonzalized = introV2SubtitlePersonzalized
            self.introV2PrimaryButtonTitle = introV2PrimaryButtonTitle
            self.introV2SecondaryButtonTitle = introV2SecondaryButtonTitle
            self.introV3Title = introV3Title
            self.introV3Subtitle = introV3Subtitle
            self.introV3Footer = introV3Footer
            self.introV3PrimaryButtonTitle = introV3PrimaryButtonTitle
            self.introV3SecondaryButtonTitle = introV3SecondaryButtonTitle
            self.wIconAccessibilityLabel = wIconAccessibilityLabel
            self.wmfLogoImageAccessibilityLabel = wmfLogoImageAccessibilityLabel
            self.personalizedExploreAccessibilityLabel = personalizedExploreAccessibilityLabel
            self.personalizedYouReadAccessibilityLabel = personalizedYouReadAccessibilityLabel
            self.personalizedUserEditsAccessibilityLabel = personalizedUserEditsAccessibilityLabel
            self.personalizedDonationThankYouAccessibilityLabel = personalizedDonationThankYouAccessibilityLabel
            self.personalizedSavedArticlesAccessibilityLabel = personalizedSavedArticlesAccessibilityLabel
            self.personalizedWeekdayAccessibilityLabel = personalizedWeekdayAccessibilityLabel
            self.personalizedYourEditsViewsAccessibilityLabel = personalizedYourEditsViewsAccessibilityLabel
            self.collectiveExploreAccessibilityLabel = collectiveExploreAccessibilityLabel
            self.collectiveLanguagesAccessibilityLabel = collectiveLanguagesAccessibilityLabel
            self.collectiveArticleViewsAccessibilityLabel = collectiveArticleViewsAccessibilityLabel
            self.collectiveSavedArticlesAccessibilityLabel = collectiveSavedArticlesAccessibilityLabel
            self.collectiveAmountEditsAccessibilityLabel = collectiveAmountEditsAccessibilityLabel
            self.englishEditsAccessibilityLabel = englishEditsAccessibilityLabel
            self.collectiveEditsPerMinuteAccessibilityLabel = collectiveEditsPerMinuteAccessibilityLabel
            self.collectiveZeroAdsAccessibilityLabel = collectiveZeroAdsAccessibilityLabel
            self.englishReadingSlideTitle = englishReadingSlideTitle
            self.englishReadingSlideSubtitle = englishReadingSlideSubtitle
            self.englishTopReadSlideTitle = englishTopReadSlideTitle
            self.englishTopReadSlideSubtitle = englishTopReadSlideSubtitle
            self.englishSavedReadingSlideTitle = englishSavedReadingSlideTitle
            self.englishSavedReadingSlideSubtitle = englishSavedReadingSlideSubtitle
            self.englishEditsSlideTitle = englishEditsSlideTitle
            self.englishEditsSlideSubtitle = englishEditsSlideSubtitle
            self.englishEditsBytesSlideTitle = englishEditsBytesSlideTitle
            self.englishEditsBytesSlideSubtitle = englishEditsBytesSlideSubtitle
            self.collectiveLanguagesSlideTitle = collectiveLanguagesSlideTitle
            self.collectiveLanguagesSlideSubtitle = collectiveLanguagesSlideSubtitle
            self.collectiveArticleViewsSlideTitle = collectiveArticleViewsSlideTitle
            self.collectiveArticleViewsSlideSubtitle = collectiveArticleViewsSlideSubtitle
            self.collectiveSavedArticlesSlideTitle = collectiveSavedArticlesSlideTitle
            self.collectiveSavedArticlesSlideSubtitle = collectiveSavedArticlesSlideSubtitle
            self.collectiveAmountEditsSlideTitle = collectiveAmountEditsSlideTitle
            self.collectiveAmountEditsSlideSubtitle = collectiveAmountEditsSlideSubtitle
            self.collectiveEditsPerMinuteSlideTitle = collectiveEditsPerMinuteSlideTitle
            self.collectiveEditsPerMinuteSlideSubtitle = collectiveEditsPerMinuteSlideSubtitle
            self.collectiveZeroAdsSlideTitle = collectiveZeroAdsSlideTitle
            self.collectiveZeroAdsSlideSubtitle = collectiveZeroAdsSlideSubtitle
            self.personalizedYouReadSlideTitleV2 = personalizedYouReadSlideTitleV2
            self.personalizedYouReadSlideSubtitleV2 = personalizedYouReadSlideSubtitleV2
            self.personalizedYouReadSlideTitleV3 = personalizedYouReadSlideTitleV3
            self.personalizedYouReadSlideSubtitleV3 = personalizedYouReadSlideSubtitleV3
            self.personalizedDateSlideTitleV2 = personalizedDateSlideTitleV2
            self.personalizedDateSlideSubtitleV2 = personalizedDateSlideSubtitleV2
            self.personalizedDateSlideTitleV3 = personalizedDateSlideTitleV3
            self.personalizedDateSlideTimeV3 = personalizedDateSlideTimeV3
            self.personalizedDateSlideTimeFooterV3 = personalizedDateSlideTimeFooterV3
            self.personalizedDateSlideDayV3 = personalizedDateSlideDayV3
            self.personalizedDateSlideDayFooterV3 = personalizedDateSlideDayFooterV3
            self.personalizedDateSlideMonthV3 = personalizedDateSlideMonthV3
            self.personalizedDateSlideMonthFooterV3 = personalizedDateSlideMonthFooterV3
            self.personalizedSaveCountSlideTitle = personalizedSaveCountSlideTitle
            self.personalizedSaveCountSlideSubtitle = personalizedSaveCountSlideSubtitle
            self.personalizedUserEditsSlideTitle = personalizedUserEditsSlideTitle
            self.personzlizedUserEditsSlideTitle500Plus = personzlizedUserEditsSlideTitle500Plus
            self.personzlizedUserEditsSlideSubtitleEN = personzlizedUserEditsSlideSubtitleEN
            self.personzlizedUserEditsSlideSubtitleNonEN = personzlizedUserEditsSlideSubtitleNonEN
            self.personalizedYourEditsViewedSlideTitle = personalizedYourEditsViewedSlideTitle
            self.personalizedYourEditsViewedSlideSubtitle = personalizedYourEditsViewedSlideSubtitle
            self.personalizedThankYouTitle = personalizedThankYouTitle
            self.personalizedThankYouSubtitle = personalizedThankYouSubtitle
            self.personalizedMostReadCategoriesSlideTitle = personalizedMostReadCategoriesSlideTitle
            self.personalizedMostReadCategoriesSlideSubtitle = personalizedMostReadCategoriesSlideSubtitle
            self.personalizedMostReadArticlesSlideTitle = personalizedMostReadArticlesSlideTitle
            self.personalizedMostReadArticlesSlideSubtitle = personalizedMostReadArticlesSlideSubtitle
            self.personalizedLocationSlideTitle = personalizedLocationSlideTitle
            self.personalizedLocationSlideSubtitle = personalizedLocationSlideSubtitle
            self.noncontributorTitle = noncontributorTitle
            self.noncontributorSubtitle = noncontributorSubtitle
            self.noncontributorButtonText = noncontributorButtonText
            self.contributorTitle = contributorTitle
            self.contributorSubtitle = contributorSubtitle
            self.contributorGiftTitle = contributorGiftTitle
            self.contributorGiftSubtitle = contributorGiftSubtitle
            self.highlightsSlideTitle = highlightsSlideTitle
            self.highlightsSlideSubtitle = highlightsSlideSubtitle
            self.highlightsSlideButtonTitle = highlightsSlideButtonTitle
            self.longestReadArticlesTitle = longestReadArticlesTitle
            self.minutesReadTitle = minutesReadTitle
            self.favoriteReadingDayTitle = favoriteReadingDayTitle
            self.savedArticlesTitle = savedArticlesTitle
            self.favoriteCategoriesTitle = favoriteCategoriesTitle
            self.editedArticlesTitle = editedArticlesTitle
            self.enWikiTopArticlesTitle = enWikiTopArticlesTitle
            self.enWikiTopArticlesValue = enWikiTopArticlesValue
            self.hoursSpentReadingTitle = hoursSpentReadingTitle
            self.hoursSpentReadingValue = hoursSpentReadingValue
            self.numberOfChangesMadeTitle = numberOfChangesMadeTitle
            self.numberOfChangesMadeValue = numberOfChangesMadeValue
            self.numberOfViewedArticlesTitle = numberOfViewedArticlesTitle
            self.numberOfViewedArticlesValue = numberOfViewedArticlesValue
            self.numberOfReadingListsTitle = numberOfReadingListsTitle
            self.numberOfEditsTitle = numberOfEditsTitle
            self.numberOfEditsValue = numberOfEditsValue
            self.editFrequencyTitle = editFrequencyTitle
            self.editFrequencyValue = editFrequencyValue
            self.logoCaption = logoCaption
        }
        
        // Navigation strings
        let donateButtonTitle: String
        let doneButtonTitle: String
        let shareButtonTitle: String
        let nextButtonTitle: String
        let finishButtonTitle: String
        public let shareText: String
        
        // Intro strings
        let introV2Title: String
        let introV2TitlePersonalized: String
        let introV2Subtitle: String
        let introV2SubtitlePersonzalized: String
        let introV2PrimaryButtonTitle: String
        let introV2SecondaryButtonTitle: String
        let introV3Title: String
        let introV3Subtitle: String
        let introV3Footer: String
        let introV3PrimaryButtonTitle: String
        let introV3SecondaryButtonTitle: String
        
        // Accessibility labels
        let wIconAccessibilityLabel: String
        let wmfLogoImageAccessibilityLabel: String
        
        let personalizedExploreAccessibilityLabel: String
        let personalizedYouReadAccessibilityLabel: String
        let personalizedUserEditsAccessibilityLabel: String
        let personalizedDonationThankYouAccessibilityLabel: String
        let personalizedSavedArticlesAccessibilityLabel: String
        let personalizedWeekdayAccessibilityLabel: String
        let personalizedYourEditsViewsAccessibilityLabel: String
        
        let collectiveExploreAccessibilityLabel: String
        let collectiveLanguagesAccessibilityLabel: String
        let collectiveArticleViewsAccessibilityLabel: String
        let collectiveSavedArticlesAccessibilityLabel: String
        let collectiveAmountEditsAccessibilityLabel: String
        let englishEditsAccessibilityLabel: String
        let collectiveEditsPerMinuteAccessibilityLabel: String
        let collectiveZeroAdsAccessibilityLabel: String
        
        // Standard Slide Strings
        let englishReadingSlideTitle: String
        let englishReadingSlideSubtitle: String
        let englishTopReadSlideTitle: String
        let englishTopReadSlideSubtitle: String
        let englishSavedReadingSlideTitle: String
        let englishSavedReadingSlideSubtitle: String
        let englishEditsSlideTitle: String
        let englishEditsSlideSubtitle: String
        let englishEditsBytesSlideTitle: String
        let englishEditsBytesSlideSubtitle: String
        let collectiveLanguagesSlideTitle: String
        let collectiveLanguagesSlideSubtitle: String
        let collectiveArticleViewsSlideTitle: String
        let collectiveArticleViewsSlideSubtitle: String
        let collectiveSavedArticlesSlideTitle: String
        let collectiveSavedArticlesSlideSubtitle: String
        let collectiveAmountEditsSlideTitle: String
        let collectiveAmountEditsSlideSubtitle: String
        let collectiveEditsPerMinuteSlideTitle: String
        let collectiveEditsPerMinuteSlideSubtitle: String
        let collectiveZeroAdsSlideTitle: String
        let collectiveZeroAdsSlideSubtitle: () -> String
        let personalizedYouReadSlideTitleV2: (Int) -> String
        let personalizedYouReadSlideSubtitleV2: (Int) -> String
        let personalizedYouReadSlideTitleV3: (Int, Int) -> String
        let personalizedYouReadSlideSubtitleV3: (Int) -> String
        let personalizedDateSlideTitleV2: (Int) -> String
        let personalizedDateSlideSubtitleV2: (Int) -> String
        let personalizedDateSlideTitleV3: String
        let personalizedDateSlideTimeV3: (Int) -> String
        let personalizedDateSlideTimeFooterV3: String
        let personalizedDateSlideDayV3: (Int) -> String
        let personalizedDateSlideDayFooterV3: String
        let personalizedDateSlideMonthV3: (Int) -> String
        let personalizedDateSlideMonthFooterV3: String
        let personalizedSaveCountSlideTitle: (Int) -> String
        let personalizedSaveCountSlideSubtitle: (Int, [String]) -> String
        let personalizedUserEditsSlideTitle: (Int) -> String
        let personzlizedUserEditsSlideTitle500Plus: String
        let personzlizedUserEditsSlideSubtitleEN: String
        let personzlizedUserEditsSlideSubtitleNonEN: String
        let personalizedYourEditsViewedSlideTitle: (Int) -> String
        let personalizedYourEditsViewedSlideSubtitle: (Int) -> String
        let personalizedThankYouTitle: String
        let personalizedThankYouSubtitle: (String) -> String
        let personalizedMostReadCategoriesSlideTitle: String
        let personalizedMostReadCategoriesSlideSubtitle: ([String]) -> String
        let personalizedMostReadArticlesSlideTitle: String
        let personalizedMostReadArticlesSlideSubtitle: ([String]) -> String
        let personalizedLocationSlideTitle: (String) -> String
        let personalizedLocationSlideSubtitle: ([String]) -> String
        // Contribution Slide Strings
        let noncontributorTitle: String
        let noncontributorSubtitle: String
        let noncontributorButtonText: String
        let contributorTitle: String
        let contributorSubtitle: (Bool, Bool) -> String
        let contributorGiftTitle: String
        let contributorGiftSubtitle: String
        // Highlights
        let highlightsSlideTitle: String
        let highlightsSlideSubtitle: String
        let highlightsSlideButtonTitle: String
        let longestReadArticlesTitle: String
        let minutesReadTitle: String
        let favoriteReadingDayTitle: String
        let savedArticlesTitle: String
        let favoriteCategoriesTitle: String
        let editedArticlesTitle: String
        let enWikiTopArticlesTitle: String
        let enWikiTopArticlesValue: [String]
        let hoursSpentReadingTitle: String
        let hoursSpentReadingValue: String
        let numberOfChangesMadeTitle: String
        let numberOfChangesMadeValue: String
        let numberOfViewedArticlesTitle: String
        let numberOfViewedArticlesValue: String
        let numberOfReadingListsTitle: String
        let numberOfEditsTitle: String
        let numberOfEditsValue: String
        let editFrequencyTitle: String
        let editFrequencyValue: String
        let logoCaption: String
    }

    @Published var currentSlideIndex = 0 {
        didSet {
            logSlideAppearance()
            if currentSlideIndex == 1 {
                hasSeenTwoSlides = true
            }
        }
    }
    @Published public var isShowingIntro: Bool = true
    @Published var donateButtonRect: CGRect = .zero
    
    public let localizedStrings: LocalizedStrings
    
    private(set) var introV2ViewModel: WMFYearInReviewIntroV2ViewModel?
    private(set) var introV3ViewModel: WMFYearInReviewIntroV3ViewModel?
    
    @Published var slides: [WMFYearInReviewSlide] // doesn't include intro
    public let shareLink: String
    public let hashtag: String
    public let plaintextURL: String
    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    private weak var badgeDelegate: YearInReviewBadgeDelegate?
    private(set) weak var loggingDelegate: WMFYearInReviewLoggingDelegate?
    private var hasSeenTwoSlides: Bool = false
    
    private var isUserPermanent: Bool // i.e. logged in
    private let primaryAppLanguage: WMFProject
    private let aboutYiRURL: URL?
    private var hasPersonalizedDonateSlide: Bool

    // Highlights
    var savedCount: Int?
    var favoriteReadingDay: WMFPageViewDay?
    var frequentCategories: [String]?
    var topReadArticles: [String]?
    var minutesRead: Int?
    var editNumber: Int?
    
    // Donate
    public var toggleAppIcon: (Bool) -> Void
    public var isIconOn: Bool

    @Published public var isLoadingDonate: Bool = false
    
    public var populateYearInReviewReport: () async throws -> Void
    @Published public var isPopulatingReport: Bool = false
    
    public init(localizedStrings: LocalizedStrings, shareLink: String, hashtag: String, plaintextURL: String, coordinatorDelegate: YearInReviewCoordinatorDelegate?, loggingDelegate: WMFYearInReviewLoggingDelegate, badgeDelegate: YearInReviewBadgeDelegate?, isUserPermanent: Bool, aboutYiRURL: URL?, primaryAppLanguage: WMFProject, toggleAppIcon: @escaping (Bool) -> Void, isIconOn: Bool, populateYearInReviewReport: @escaping () async throws -> Void) {

        self.localizedStrings = localizedStrings
        self.shareLink = shareLink
        self.hashtag = hashtag
        self.plaintextURL = plaintextURL
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.badgeDelegate = badgeDelegate
        self.isUserPermanent = isUserPermanent
        self.primaryAppLanguage = primaryAppLanguage
        self.aboutYiRURL = aboutYiRURL
        self.toggleAppIcon = toggleAppIcon
        self.isIconOn = isIconOn
        self.populateYearInReviewReport = populateYearInReviewReport
        
        // Default inits to avoid compiler complaints later in this method
        self.introV2ViewModel = nil
        self.introV3ViewModel = nil
        self.slides = []
        self.hasPersonalizedDonateSlide = false
        
        self.setupIntro(isUserPermanent: isUserPermanent)
    }
    
    // MARK: Personalized Slides
    
    private struct PersonalizedSlides {
        var readCountSlideV2: WMFYearInReviewSlideStandardViewModel?
        var readCountSlideV3: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlideV2: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlideV3: WMFYearInReviewContributorSlideViewModel?
        var saveCountSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadDateSlideV2: WMFYearInReviewSlideStandardViewModel?
        var mostReadDateSlideV3: WMFYearInReviewSlideMostReadDateV3ViewModel?
        var viewCountSlide: WMFYearInReviewSlideStandardViewModel?
        var topArticlesSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadCategoriesSlide: WMFYearInReviewSlideStandardViewModel?
        var locationSlide: WMFYearInReviewSlideLocationViewModel?
    }
    
    private func getPersonalizedSlides(aboutYiRURL: URL?) -> PersonalizedSlides {
        // Personalized Slides
        var readCountSlideV2: WMFYearInReviewSlideStandardViewModel?
        var readCountSlideV3: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlideV2: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlideV3: WMFYearInReviewContributorSlideViewModel?
        var saveCountSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadDateSlideV2: WMFYearInReviewSlideStandardViewModel?
        var mostReadDateSlideV3: WMFYearInReviewSlideMostReadDateV3ViewModel?
        var viewCountSlide: WMFYearInReviewSlideStandardViewModel?
        var topArticlesSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadCategoriesSlide: WMFYearInReviewSlideStandardViewModel?
        var locationSlide: WMFYearInReviewSlideLocationViewModel?
        
        let dataController = try? WMFYearInReviewDataController()
        
        // Fetch YiR report for personalized data, assign to personalized slides
        if let dataController,
           let report = try? dataController.fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear) {
            for slide in report.slides {
                switch slide.id {
                case .readCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let readData = try? decoder.decode(WMFYearInReviewReadData.self, from: data),
                           readData.readCount > 5 {
                            minutesRead = readData.minutesRead
                            readCountSlideV2 = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-01",
                                altText: localizedStrings.personalizedYouReadAccessibilityLabel,
                                title: localizedStrings.personalizedYouReadSlideTitleV2(readData.readCount),
                                subtitle: localizedStrings.personalizedYouReadSlideSubtitleV2(readData.readCount),
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "read_count_custom",
                                tappedInfo: tappedInfo
                            )
                            
                            readCountSlideV3 = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-01",
                                altText: localizedStrings.personalizedYouReadAccessibilityLabel,
                                title: localizedStrings.personalizedYouReadSlideTitleV3(readData.readCount, readData.minutesRead),
                                subtitle: localizedStrings.personalizedYouReadSlideSubtitleV3(readData.readCount),
                                subtitleType: .html,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "read_count_custom",
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .editCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let editCount = try? decoder.decode(Int.self, from: data),
                           editCount > 0 {
                            editNumber = editCount
                            editCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-04",
                                altText: localizedStrings.personalizedUserEditsAccessibilityLabel,
                                title: editCount >= 500 ? localizedStrings.personzlizedUserEditsSlideTitle500Plus : localizedStrings.personalizedUserEditsSlideTitle(editCount),
                                subtitle: primaryAppLanguage.isEnglishWikipedia ? localizedStrings.personzlizedUserEditsSlideSubtitleEN : localizedStrings.personzlizedUserEditsSlideSubtitleNonEN,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "edit_count_custom",
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .donateCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let donateSlideData = try? decoder.decode(DonateAndEditCounts.self, from: data) {
                            let donateCount = donateSlideData.donateCount ?? 0
                            let editCount = donateSlideData.editCount ?? 0
                            
                            if donateCount > 0 || editCount > 0 {
                                donateCountSlideV3 = WMFYearInReviewContributorSlideViewModel(
                                    gifName: "contribution-slide",
                                    altText: "",
                                    title: localizedStrings.contributorTitle,
                                    subtitle: localizedStrings.contributorSubtitle(editCount > 0, donateCount > 0),
                                    loggingID: "", // todo
                                    contributionStatus: .contributor,
                                    onTappedDonateButton: { [weak self] in
                                        self?.handleDonate()
                                    },
                                    onToggleIcon: { isOn in
                                        self.toggleAppIcon(isOn)
                                    },
                                    onInfoButtonTap: tappedInfo,
                                    donateButtonTitle: localizedStrings.donateButtonTitle,
                                    toggleButtonTitle: localizedStrings.contributorGiftTitle,
                                    toggleButtonSubtitle: localizedStrings.contributorGiftSubtitle,
                                    isIconOn: isIconOn,
                                    infoURL: aboutYiRURL
                                )
                            }
                            
                            if donateCount > 0 {
                                donateCountSlideV2 = WMFYearInReviewSlideStandardViewModel(
                                gifName: "all-slide-06",
                                altText: localizedStrings.personalizedDonationThankYouAccessibilityLabel,
                                title: localizedStrings.personalizedThankYouTitle,
                                subtitle: localizedStrings.personalizedThankYouSubtitle(primaryAppLanguage.languageCode ?? "en"),
                                subtitleType: .markdown,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: true,
                                loggingID: "thank_custom",
                                tappedLearnMore: tappedLearnMore(url:),
                                tappedInfo: tappedInfo)
                            }
                        }
                    }
                case .saveCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let savedSlideData = try? decoder.decode(SavedArticleSlideData.self, from: data),
                           savedSlideData.savedArticlesCount > 3,
                           savedSlideData.articleTitles.count >= 3 {
                            let count = savedSlideData.savedArticlesCount
                            savedCount = count
                            saveCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-03",
                                altText: localizedStrings.personalizedSavedArticlesAccessibilityLabel,
                                title: localizedStrings.personalizedSaveCountSlideTitle(count),
                                subtitle: localizedStrings.personalizedSaveCountSlideSubtitle(count, savedSlideData.articleTitles),
                                subtitleType: .html,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "save_count_custom",
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .mostReadDate:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let mostReadDates = try? decoder.decode(WMFPageViewDates.self, from: data),
                           let mostReadDay = mostReadDates.days.first,
                           let mostReadTime = mostReadDates.times.first,
                           let mostReadMonth = mostReadDates.months.first,
                           mostReadDay.viewCount > 0,
                           mostReadTime.viewCount > 0,
                           mostReadMonth.viewCount > 0 {
                            favoriteReadingDay = mostReadDay

                            mostReadDateSlideV2 = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-02",
                                altText: localizedStrings.personalizedWeekdayAccessibilityLabel,
                                title: localizedStrings.personalizedDateSlideTitleV2(mostReadDay.day),
                                subtitle: localizedStrings.personalizedDateSlideSubtitleV2(mostReadDay.day),
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "read_day_custom",
                                tappedInfo: tappedInfo
                            )
                            
                            mostReadDateSlideV3 = WMFYearInReviewSlideMostReadDateV3ViewModel(
                                gifName: "personal-slide-02",
                                altText: localizedStrings.personalizedWeekdayAccessibilityLabel,
                                title: localizedStrings.personalizedDateSlideTitleV3,
                                time: localizedStrings.personalizedDateSlideTimeV3(mostReadTime.hour),
                                timeFooter: localizedStrings.personalizedDateSlideTimeFooterV3,
                                day: localizedStrings.personalizedDateSlideDayV3(mostReadDay.day),
                                dayFooter: localizedStrings.personalizedDateSlideDayFooterV3,
                                month: localizedStrings.personalizedDateSlideMonthV3(mostReadMonth.month),
                                monthFooter: localizedStrings.personalizedDateSlideMonthFooterV3,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "read_day_custom",
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .viewCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let viewCount = try? decoder.decode(Int.self, from: data),
                           viewCount > 0 {
                            
                            viewCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-05",
                                altText: localizedStrings.personalizedYourEditsViewsAccessibilityLabel,
                                title: localizedStrings.personalizedYourEditsViewedSlideTitle(viewCount),
                                subtitle: localizedStrings.personalizedYourEditsViewedSlideSubtitle(viewCount),
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "edit_view_count_custom",
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .mostReadCategories:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let mostReadCategories = try? decoder.decode([String].self, from: data), mostReadCategories.count >= 3 {
                            frequentCategories = mostReadCategories
                            mostReadCategoriesSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-05", // TODO: modify gif name
                                altText: "", // TODO: alt text
                                title: localizedStrings.personalizedMostReadCategoriesSlideTitle,
                                subtitle: localizedStrings.personalizedMostReadCategoriesSlideSubtitle(mostReadCategories),
                                subtitleType: .standard,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "", // TODO: logging ID,
                                tappedInfo: tappedInfo)
                        }
                    }
                case .topArticles:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let topArticles = try? decoder.decode([String].self, from: data),
                           topArticles.count > 0 {
                            topReadArticles = topArticles
                            topArticlesSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "english-slide-02", // TODO: modify gif name
                                altText: "", // TODO: alt text
                                title: localizedStrings.personalizedMostReadArticlesSlideTitle,
                                subtitle: localizedStrings.personalizedMostReadArticlesSlideSubtitle(topArticles),
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "", // TODO: logging ID
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .location:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let legacyPageViews = try? decoder.decode([WMFLegacyPageView].self, from: data),
                           legacyPageViews.count >= 2 {
                            locationSlide = WMFYearInReviewSlideLocationViewModel(
                                localizedStrings: localizedStrings,
                                legacyPageViews: legacyPageViews,
                                loggingID: "", // TODO: Logging ID
                                infoURL: aboutYiRURL,
                                tappedInfo: tappedInfo)
                        }
                    }
                }
            }
        }

        return PersonalizedSlides(readCountSlideV2: readCountSlideV2, readCountSlideV3: readCountSlideV3, editCountSlide: editCountSlide, donateCountSlideV2: donateCountSlideV2, donateCountSlideV3: donateCountSlideV3, saveCountSlide: saveCountSlide, mostReadDateSlideV2: mostReadDateSlideV2, mostReadDateSlideV3: mostReadDateSlideV3, viewCountSlide: viewCountSlide, topArticlesSlide: topArticlesSlide, mostReadCategoriesSlide: mostReadCategoriesSlide, locationSlide: locationSlide)
    }
    
    private func setupIntro(isUserPermanent: Bool) {

        self.isUserPermanent = isUserPermanent
        
        // Intro slide
        if WMFDeveloperSettingsDataController.shared.showYiRV3 {
            let introV3LoggingID = "" // TODO: logging ID
            let introV3ViewModel = WMFYearInReviewIntroV3ViewModel(
                gifName: "personal-slide-00",
                altText: localizedStrings.personalizedExploreAccessibilityLabel,
                title: localizedStrings.introV3Title,
                subtitle: localizedStrings.introV3Subtitle,
                footer: localizedStrings.introV3Footer,
                primaryButtonTitle: localizedStrings.introV3PrimaryButtonTitle,
                secondaryButtonTitle: localizedStrings.introV3SecondaryButtonTitle,
                loggingID: introV3LoggingID,
                onAppear: { [weak self] in
                    self?.loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: introV3LoggingID)
                    self?.markFirstSlideAsSeen()
                },
                tappedPrimaryButton: { [weak self] in
                    self?.tappedIntroV3GetStarted()
                },
                tappedSecondaryButton: { [weak self] in
                    self?.loggingDelegate?.logYearInReviewIntroDidTapLearnMore()
                    self?.coordinatorDelegate?.handleYearInReviewAction(.introLearnMore)
                }
            )
            self.introV3ViewModel = introV3ViewModel
        } else if WMFDeveloperSettingsDataController.shared.showYiRV2 {
            let introV2LoggingID = isUserPermanent ? "start_c" : "start"
            let introV2ViewModel = WMFYearInReviewIntroV2ViewModel(
                gifName: isUserPermanent ? "personal-slide-00" : "english-slide-00",
                altText: isUserPermanent ? localizedStrings.personalizedExploreAccessibilityLabel : localizedStrings.collectiveExploreAccessibilityLabel,
                title: isUserPermanent ? localizedStrings.introV2TitlePersonalized : localizedStrings.introV2Title,
                subtitle: isUserPermanent ? localizedStrings.introV2SubtitlePersonzalized : localizedStrings.introV2Subtitle,
                primaryButtonTitle: localizedStrings.introV2PrimaryButtonTitle,
                secondaryButtonTitle: localizedStrings.introV2SecondaryButtonTitle,
                loggingID: introV2LoggingID,
                onAppear: { [weak self] in
                    self?.loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: introV2LoggingID)
                    self?.markFirstSlideAsSeen()
                },
                tappedPrimaryButton: { [weak self] in
                    self?.tappedIntroV2GetStarted()
                },
                tappedSecondaryButton: { [weak self] in
                    self?.loggingDelegate?.logYearInReviewIntroDidTapLearnMore()
                    self?.coordinatorDelegate?.handleYearInReviewAction(.introLearnMore)
                }
            )
            self.introV2ViewModel = introV2ViewModel
        }
    }
    
    private func updateSlides(isUserPermanent: Bool) {

        var slides: [WMFYearInReviewSlide] = []
        
        let personalizedSlides = getPersonalizedSlides(aboutYiRURL: aboutYiRURL)
        
        if WMFDeveloperSettingsDataController.shared.showYiRV3 {
            if isUserPermanent {
                slides.append(.standard(personalizedSlides.readCountSlideV3 ?? (primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide)))
                
                if primaryAppLanguage.isEnglishWikipedia {
                    slides.append(.standard(englishTopReadSlide))
                    
                    if let topArticlesSlide = personalizedSlides.topArticlesSlide {
                        slides.append(.standard(topArticlesSlide))
                    }
                    
                    if let mostReadDateSlideV3 = personalizedSlides.mostReadDateSlideV3 {
                        slides.append(.mostReadDateV3(mostReadDateSlideV3))
                    }
                    
                    if let categorySlide = personalizedSlides.mostReadCategoriesSlide {
                        slides.append(.standard(categorySlide))
                    }
                    
                    if let locationSlide = personalizedSlides.locationSlide {
                        slides.append(.location(locationSlide))
                    }
                    
                } else {
                    slides.append(.standard(collectiveArticleViewsSlide))
                    
                    if let topArticlesSlide = personalizedSlides.topArticlesSlide {
                        slides.append(.standard(topArticlesSlide))
                    }
                    
                    if let mostReadDateSlideV3 = personalizedSlides.mostReadDateSlideV3 {
                        slides.append(.mostReadDateV3(mostReadDateSlideV3))
                    }
                    
                    if let categorySlide = personalizedSlides.mostReadCategoriesSlide {
                        slides.append(.standard(categorySlide))
                    }
                    
                    if let locationSlide = personalizedSlides.locationSlide {
                        slides.append(.location(locationSlide))
                    }
                }

                slides.append(.standard(personalizedSlides.saveCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide)))
                slides.append(.standard(personalizedSlides.editCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide)))
                slides.append(.standard(personalizedSlides.viewCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide)))
                slides.append(.contribution(personalizedSlides.donateCountSlideV3 ?? nonContributorSlide))
                slides.append(.highlights(getPersonalizedHighlights()))
            } else {
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide))
                slides.append(.contribution(personalizedSlides.donateCountSlideV3 ?? nonContributorSlide))
                slides.append(.highlights(primaryAppLanguage.isEnglishWikipedia ? getEnglishCollectiveHighlights() : getCollectiveHighlights()))
            }
        } else if WMFDeveloperSettingsDataController.shared.showYiRV2 {
            if isUserPermanent {
                slides.append(.standard(personalizedSlides.readCountSlideV2 ?? (primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide)))
                slides.append(.standard(personalizedSlides.mostReadDateSlideV2 ?? (primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide)))
                slides.append(.standard(personalizedSlides.saveCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide)))
                slides.append(.standard(personalizedSlides.editCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide)))
                slides.append(.standard(personalizedSlides.viewCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide)))
                slides.append(.standard(personalizedSlides.donateCountSlideV2 ?? collectiveZeroAdsSlide))
            } else {
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide))
                slides.append(.standard(personalizedSlides.donateCountSlideV2 ?? collectiveZeroAdsSlide))
            }
        }
        
        self.slides = slides
        
        if personalizedSlides.donateCountSlideV2 != nil || personalizedSlides.donateCountSlideV3 != nil {
            self.hasPersonalizedDonateSlide = true
        }
    }

    func getPersonalizedHighlights() -> WMFYearInReviewSlideHighlightsViewModel {
        var itemArray: [TableItem] = []

        if let topReadArticles {
            let top3 = topReadArticles.prefix(3)
            let articleList = makeNumberedBlueList(Array(top3), needsLinkColor: true)
            let topArticlesItem = TableItem(title: localizedStrings.longestReadArticlesTitle, richRows: articleList)

            itemArray.append(topArticlesItem)
        }

        if let minutesRead {
            let timeItem = TableItem(title: localizedStrings.minutesReadTitle, text: String(minutesRead))
            itemArray.append(timeItem)
        }

        if let favoriteReadingDay {
            let mostReadTimeItem = TableItem(title: localizedStrings.favoriteReadingDayTitle, text: localizedStrings.personalizedDateSlideDayV3(favoriteReadingDay.day))
            itemArray.append(mostReadTimeItem)
        }

        if savedCount != nil, let savedCount {
            let savedCountItem = TableItem(title: localizedStrings.savedArticlesTitle, text: String(savedCount))
            itemArray.append(savedCountItem)
        }

        if let frequentCategories {
            let top3 = frequentCategories.prefix(3)
            let categoryList = makeNumberedBlueList(Array(top3), needsLinkColor: false)
            let categoriesItem = TableItem(title: localizedStrings.favoriteCategoriesTitle, richRows: categoryList)
            itemArray.append(categoriesItem)
        }
        
        if let editNumber, editNumber > 0 {
            let editCountItem = TableItem(title: localizedStrings.editedArticlesTitle, text: String(editNumber))
            itemArray.append(editCountItem)
        }

        return WMFYearInReviewSlideHighlightsViewModel(
            infoBoxViewModel: WMFInfoboxViewModel(tableItems: itemArray),
            loggingID: "",  // TODO: logging ID
            localizedStrings: getHighlightsStrings(),
            coordinatorDelegate: coordinatorDelegate,
            hashtag: hashtag,
            plaintextURL: plaintextURL
        )
    }

    // MARK: - English Slides

    func getEnglishCollectiveHighlights() -> WMFYearInReviewSlideHighlightsViewModel {
        let articles = localizedStrings.enWikiTopArticlesValue

        let blueList = makeNumberedBlueList(articles, needsLinkColor: true)

        let topArticles = TableItem(title: localizedStrings.enWikiTopArticlesTitle, richRows: blueList)
        let hoursSpent = TableItem(title: localizedStrings.hoursSpentReadingTitle, text: localizedStrings.hoursSpentReadingValue)
        let changesMade = TableItem(title: localizedStrings.numberOfChangesMadeTitle, text: localizedStrings.numberOfChangesMadeValue)
        return WMFYearInReviewSlideHighlightsViewModel(
            infoBoxViewModel: WMFInfoboxViewModel(tableItems: [topArticles, hoursSpent, changesMade]),
            loggingID: "", // TODO: logging ID
            localizedStrings: getHighlightsStrings(),
            coordinatorDelegate: coordinatorDelegate,
            hashtag: hashtag,
            plaintextURL: plaintextURL
        )
    }

    private var englishHoursReadingSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-01",
            altText: localizedStrings.collectiveEditsPerMinuteAccessibilityLabel,
            title: localizedStrings.englishReadingSlideTitle,
            subtitle: localizedStrings.englishReadingSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "en_read_hours_base",
            tappedInfo: tappedInfo
        )
    }
    
    private var englishTopReadSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-02",
            altText: localizedStrings.collectiveArticleViewsAccessibilityLabel,
            title: localizedStrings.englishTopReadSlideTitle,
            subtitle: localizedStrings.englishTopReadSlideSubtitle,
            subtitleType: .html,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "en_most_visit_base",
            tappedInfo: tappedInfo
        )
    }
    
    private var englishReadingListSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-03",
            altText: localizedStrings.collectiveSavedArticlesAccessibilityLabel,
            title: localizedStrings.englishSavedReadingSlideTitle,
            subtitle: localizedStrings.englishSavedReadingSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "en_list_count_base",
            tappedInfo: tappedInfo
        )
    }
    
    private var englishEditsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-04",
            altText: localizedStrings.englishEditsAccessibilityLabel,
            title: localizedStrings.englishEditsSlideTitle,
            subtitle: localizedStrings.englishEditsSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "en_edit_count_base",
            tappedInfo: tappedInfo
        )
    }
    
    private var englishEditsBytesSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-05",
            altText: localizedStrings.personalizedUserEditsAccessibilityLabel,
            title: localizedStrings.englishEditsBytesSlideTitle,
            subtitle: localizedStrings.englishEditsBytesSlideSubtitle,
            subtitleType: .markdown,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "en_byte_base",
            tappedInfo: tappedInfo
        )
    }

    // MARK: - Collective Slides

    // TODO: Get real numbers
    // TODO: Confirm copy
    func getCollectiveHighlights() -> WMFYearInReviewSlideHighlightsViewModel {
        let viewedArticles = TableItem(title: localizedStrings.numberOfViewedArticlesTitle, text: localizedStrings.numberOfViewedArticlesValue)
        // let readingLists = TableItem(title: localizedStrings.numberOfReadingListsTitle, text: "987654321")
        let edits = TableItem(title: localizedStrings.numberOfEditsTitle, text: localizedStrings.numberOfEditsValue)
        let editFrequency = TableItem(title: localizedStrings.editFrequencyTitle, text: localizedStrings.editFrequencyValue)
        return WMFYearInReviewSlideHighlightsViewModel(
            infoBoxViewModel: WMFInfoboxViewModel(tableItems: [viewedArticles, edits, editFrequency]),
            loggingID: "", // TODO: logging ID
            localizedStrings: getHighlightsStrings(),
            coordinatorDelegate: coordinatorDelegate,
            hashtag: hashtag,
            plaintextURL: plaintextURL
        )
    }

    private var collectiveLanguagesSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "non-english-slide-01",
            altText: localizedStrings.collectiveLanguagesAccessibilityLabel,
            title: localizedStrings.collectiveLanguagesSlideTitle,
            subtitle: localizedStrings.collectiveLanguagesSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "read_count_base",
            tappedInfo: tappedInfo
        )
    }
    
    private var collectiveArticleViewsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-02",
            altText: localizedStrings.collectiveArticleViewsAccessibilityLabel,
            title: localizedStrings.collectiveArticleViewsSlideTitle,
            subtitle: localizedStrings.collectiveArticleViewsSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "read_view_base",
            tappedInfo: tappedInfo
        )
    }

    private var collectiveSavedArticlesSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-03",
            altText: localizedStrings.collectiveSavedArticlesAccessibilityLabel,
            title: localizedStrings.collectiveSavedArticlesSlideTitle,
            subtitle: localizedStrings.collectiveSavedArticlesSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "list_count_base",
            tappedInfo: tappedInfo
        )
    }

    private var collectiveAmountEditsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "non-english-slide-04",
            altText: localizedStrings.collectiveAmountEditsAccessibilityLabel,
            title: localizedStrings.collectiveAmountEditsSlideTitle,
            subtitle: localizedStrings.collectiveAmountEditsSlideSubtitle,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "edit_count_base",
            tappedInfo: tappedInfo
        )
    }
    
    private var collectiveEditsPerMinuteSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "english-slide-01",
            altText: localizedStrings.collectiveEditsPerMinuteAccessibilityLabel,
            title: localizedStrings.collectiveEditsPerMinuteSlideTitle,
            subtitle: localizedStrings.collectiveEditsPerMinuteSlideSubtitle,
            subtitleType: .markdown,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "edit_rate_base",
            tappedInfo: tappedInfo
        )
    }

    private var collectiveZeroAdsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "all-slide-06",
            altText: localizedStrings.collectiveZeroAdsAccessibilityLabel,
            title: localizedStrings.collectiveZeroAdsSlideTitle,
            subtitle: localizedStrings.collectiveZeroAdsSlideSubtitle(),
            subtitleType: .markdown,
            infoURL: aboutYiRURL,
            forceHideDonateButton: false,
            loggingID: "ads_served_base",
            tappedLearnMore: tappedLearnMore(url:),
            tappedInfo: tappedInfo
        )
    }
    
    private var nonContributorSlide: WMFYearInReviewContributorSlideViewModel {
        let forceHideDonateButton = (try? WMFYearInReviewDataController().shouldHideDonateButton()) ?? false
        return WMFYearInReviewContributorSlideViewModel(
            gifName: "contribution-slide",
            altText: "",
            title: localizedStrings.noncontributorTitle,
            subtitle: localizedStrings.noncontributorSubtitle,
            loggingID: "",
            contributionStatus: .noncontributor,
            forceHideDonateButton: forceHideDonateButton,
            onTappedDonateButton: { [weak self] in
                self?.handleDonate()
            },
            onInfoButtonTap: tappedInfo,
            donateButtonTitle: localizedStrings.donateButtonTitle,
            toggleButtonTitle: localizedStrings.contributorGiftTitle,
            toggleButtonSubtitle: localizedStrings.contributorGiftSubtitle,
            infoURL: aboutYiRURL)
    }
    
    private var currentSlide: WMFYearInReviewSlide {
        return slides[currentSlideIndex]
    }
    
    func tappedIntroV2GetStarted() {
        loggingDelegate?.logYearInReviewIntroDidTapContinue()
        populateReportAndShowFirstSlide()
    }
    
    func tappedIntroV3GetStarted() {
        if !isUserPermanent {
            coordinatorDelegate?.handleYearInReviewAction(.tappedIntroV3GetStartedWhileLoggedOut)
        } else {
            populateReportAndShowFirstSlide()
        }
    }
    
    private func populateReportAndUpdateSlides() {
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.populateYearInReviewReport()
                Task { @MainActor [weak self] in
                    
                    guard let self else { return }
                    
                    self.updateSlides(isUserPermanent: isUserPermanent)
                }
            } catch {
                // do nothing
            }
        }
    }
    
    private func populateReportAndShowFirstSlide() {
        isPopulatingReport = true
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.populateYearInReviewReport()
                Task { @MainActor [weak self] in
                    
                    guard let self else { return }
                    
                    self.updateSlides(isUserPermanent: isUserPermanent)
                    self.isPopulatingReport = false
                    self.loggingDelegate?.logYearInReviewIntroDidTapContinue()
                    self.logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
                    
                    // Maybe delay a little bit to let slide changes propagate
                    try await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation {
                        self.isShowingIntro = false
                    }
                }
            } catch {
                Task { @MainActor [weak self] in
                    
                    guard let self else { return }
                    
                    self.updateSlides(isUserPermanent: isUserPermanent)
                    self.isPopulatingReport = false
                    self.loggingDelegate?.logYearInReviewIntroDidTapContinue()
                    self.logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
                    
                    // Maybe delay a little bit to let slide changes propagate
                    try await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation {
                        self.isShowingIntro = false
                    }
                }
            }
        }
    }
    
    public func tappedIntroV3LoginPromptNoThanks() {
        isUserPermanent = false
        populateReportAndShowFirstSlide()
    }
    
    public func tappedIntroV3ExitConfirmationGetStarted() {
        isUserPermanent = false
        populateReportAndShowFirstSlide()
    }
    
    public func completedLoginFromIntroV3LoginPrompt() {
        isUserPermanent = true
        populateReportAndShowFirstSlide()
    }
    
    public func donateDidSucceed() {
        populateReportAndUpdateSlides()
    }
    
    private func incrementSlideIndex() {
        currentSlideIndex = (currentSlideIndex + 1) % slides.count
    }
    
    func tappedNext() {
        logYearInReviewSlideDidTapNext()
        if isLastSlide {
            coordinatorDelegate?.handleYearInReviewAction(.dismiss(hasSeenTwoSlides: true))
        } else {
            incrementSlideIndex()
        }
    }

    @MainActor func tappedShare() {
        switch currentSlide {
        case .standard(let viewModel):
            let needsMarkdownSubtitle: Bool
            switch viewModel.subtitleType {
            case .html:
                needsMarkdownSubtitle = false
            case .markdown:
                needsMarkdownSubtitle = true
            case .standard:
                needsMarkdownSubtitle = false
            }
            let view = WMFYearInReviewSlideStandardShareableView(viewModel: viewModel, hashtag: hashtag, needsMarkdownSubtitle: needsMarkdownSubtitle)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = .init(width: 402, height: nil)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                coordinatorDelegate?.handleYearInReviewAction(.share(image: uiImage))
            }
        case .mostReadDateV3(let viewModel):
            let view = WMFYearInReviewSlideMostReadDateV3ShareableView(viewModel: viewModel, hashtag: hashtag)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = .init(width: 402, height: nil)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                coordinatorDelegate?.handleYearInReviewAction(.share(image: uiImage))
            }
        case .location(let viewModel):
            if viewModel.isLoading || viewModel.mapViewSnapshotForSharing == nil {
                return
            }
            let view = WMFYearInReviewSlideLocationShareableView(viewModel: viewModel, hashtag: hashtag)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = .init(width: 402, height: nil)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                coordinatorDelegate?.handleYearInReviewAction(.share(image: uiImage))
            }
        case .contribution(let viewModel):
            let needsMarkdownSubtitle: Bool
            // Handles the "Learn more" link
            switch viewModel.contributionStatus {
            case .contributor:
                needsMarkdownSubtitle = false
            case .noncontributor:
                needsMarkdownSubtitle = true
            }
            let view = WMFYearInReviewSlideStandardShareableView(viewModel: viewModel, hashtag: hashtag, needsMarkdownSubtitle: needsMarkdownSubtitle)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = .init(width: 402, height: nil)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                coordinatorDelegate?.handleYearInReviewAction(.share(image: uiImage))
            }
            break
        case .highlights:
            break
        }
        logYearInReviewDidTapShare()
    }
    
    func tappedDone() {
        let standardDismissal: () -> Void = { [weak self] in
            guard let self else { return }
            logYearInReviewDidTapDone()
            coordinatorDelegate?.handleYearInReviewAction(.dismiss(hasSeenTwoSlides: hasSeenTwoSlides))
        }
        
        if !isShowingIntro {
            standardDismissal()
        } else if WMFDeveloperSettingsDataController.shared.showYiRV2 {
            standardDismissal()
        } else if WMFDeveloperSettingsDataController.shared.showYiRV3 {
            if isUserPermanent {
                standardDismissal()
            } else {
                coordinatorDelegate?.handleYearInReviewAction(.tappedIntroV3DoneWhileLoggedOut)
            }
        }
    }
    
    func handleDonate() {
        let getSourceRect: () -> CGRect = { [weak self] in
            return self?.donateButtonRect ?? .zero
        }
        coordinatorDelegate?.handleYearInReviewAction(.donate(getSourceRect: getSourceRect))
        logYearInReviewDidTapDonate()
    }
    
    private var slideLoggingID: String {
        if isShowingIntro {
            if let introV2ViewModel {
                return introV2ViewModel.loggingID
            } else if let introV3ViewModel {
                return introV3ViewModel.loggingID
            }
        }
        switch currentSlide {
        case .standard(let viewModel):
            return viewModel.loggingID
        case .location(let viewModel):
            return viewModel.loggingID
        case .contribution(let viewModel):
            return viewModel.loggingID
        case .highlights(let viewModel):
            return viewModel.loggingID
        case .mostReadDateV3(let viewModel):
			return viewModel.loggingID
        }
    }
    
    var shouldShowDonateButton: Bool {
        if isShowingIntro {
            return false
        }
        
        // Config has certain countries that do not show donate button
        let configShouldHide = (try? WMFYearInReviewDataController().shouldHideDonateButton()) ?? false
        if configShouldHide {
            return false
        }
        
        let slide = currentSlide
        switch slide {
        case .standard(let viewModel):
            if viewModel.forceHideDonateButton {
                return false
            } else {
                return true
            }
        case .contribution(let viewModel):
            if viewModel.contributionStatus == .contributor {
                if viewModel.forceHideDonateButton {
                    return false
                }
                
                return true
            }
            return false
        default:
            return true
        }
    }
    
    func tappedLearnMore(url: URL) {
        var shouldShowDonate = false
        if slides.count - 1 == currentSlideIndex && !hasPersonalizedDonateSlide {
            shouldShowDonate = true
        }

        // Always verify for regions we cannot ask for donations
        shouldShowDonate = !shouldHideDonateButtonForCertainRegions()

        coordinatorDelegate?.handleYearInReviewAction(.learnMore(url: url, shouldShowDonateButton: shouldShowDonate))
        loggingDelegate?.logYearInReviewDonateDidTapLearnMore(slideLoggingID: slideLoggingID)
    }

    private func logYearInReviewSlideDidAppear() {
        loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: slideLoggingID)
    }
    
    public func logYearInReviewDidTapDone() {
        loggingDelegate?.logYearInReviewDidTapDone(slideLoggingID: slideLoggingID)
    }
    
    private func logYearInReviewSlideDidTapNext() {
        loggingDelegate?.logYearInReviewDidTapNext(slideLoggingID: slideLoggingID)
    }
    
    private func logYearInReviewDidTapDonate() {
        loggingDelegate?.logYearInReviewDidTapDonate(slideLoggingID: slideLoggingID)
    }
    
    private func logYearInReviewDidTapShare() {
        loggingDelegate?.logYearInReviewDidTapShare(slideLoggingID: slideLoggingID)
    }
    
    var isLastSlide: Bool {
        return currentSlideIndex == slides.count - 1
    }

    private func markFirstSlideAsSeen() {
        if let dataController = try? WMFYearInReviewDataController() {
            dataController.hasSeenYiRIntroSlide = true
            badgeDelegate?.updateYIRBadgeVisibility()
        }
    }

    func tappedInfo() {
        switch currentSlide {
        case .standard(let vm):
            coordinatorDelegate?.handleYearInReviewAction(.info(url: vm.infoURL))
        case .mostReadDateV3(let vm):
            coordinatorDelegate?.handleYearInReviewAction(.info(url: vm.infoURL))
        case .location(let vm):
            coordinatorDelegate?.handleYearInReviewAction(.info(url: vm.infoURL))
        case .contribution(let vm):
            coordinatorDelegate?.handleYearInReviewAction(.info(url: vm.infoURL))
        case .highlights:
            break
        }
    }
    
    private func logSlideAppearance() {
        logYearInReviewSlideDidAppear()
    }

    func shouldHideDonateButtonForCertainRegions() -> Bool {
        guard let dataController = try? WMFYearInReviewDataController() else {
            return false
        }
        return dataController.shouldHideDonateButton()
    }

    private func getHighlightsStrings() -> WMFYearInReviewSlideHighlightsViewModel.LocalizedStrings {
        return WMFYearInReviewSlideHighlightsViewModel.LocalizedStrings(title: localizedStrings.highlightsSlideTitle, subtitle: localizedStrings.highlightsSlideSubtitle, buttonTitle: localizedStrings.highlightsSlideButtonTitle, logoCaption: localizedStrings.logoCaption)
    }

    // Helper methods to format the infobox on the highlights slide
    public enum LineLimitStrategy {
        case automatic
        case fixed(Int)
    }

    private func resolvedLineLimit(_ strategy: LineLimitStrategy) -> Int {
        switch strategy {
        case .automatic:
            return UIDevice.current.userInterfaceIdiom == .pad ? 3 : 3
        case .fixed(let n):
            return n
        }
    }

    /// Helper method to format the infobox on the highlights slide
    func makeNumberedBlueList(_ articles: [String], needsLinkColor: Bool) -> [InfoboxRichRow] {
        articles.enumerated().map { (i, title) in
            var numberRun = AttributedString("\(i + 1). ")
            numberRun.foregroundColor = Color(WMFColor.black)

            var titleRun = AttributedString(title)
            titleRun.foregroundColor = needsLinkColor ? Color(WMFColor.blue600) : Color(WMFColor.black)

            return InfoboxRichRow(numberText: numberRun, titleText: titleRun)
        }
    }

}

enum WMFYearInReviewSlide {
    case standard(WMFYearInReviewSlideStandardViewModel)
    case location(WMFYearInReviewSlideLocationViewModel)
    case contribution(WMFYearInReviewContributorSlideViewModel)
    case mostReadDateV3(WMFYearInReviewSlideMostReadDateV3ViewModel)
    case highlights(WMFYearInReviewSlideHighlightsViewModel)
    // todo: articles read
}

@objc public protocol YearInReviewBadgeDelegate: AnyObject {
    @objc func updateYIRBadgeVisibility()
}
