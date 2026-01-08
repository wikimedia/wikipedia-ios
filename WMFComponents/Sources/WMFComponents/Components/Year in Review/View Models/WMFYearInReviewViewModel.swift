import Foundation
import SwiftUI
import WMFData

public protocol WMFYearInReviewLoggingDelegate: AnyObject {
    func logYearInReviewIntroDidTapLearnMore()
    func logYearInReviewSlideDidAppear(slideLoggingID: String)
    func logYearInReviewDidTapDone(slideLoggingID: String)
    func logYearInReviewDidTapNext(slideLoggingID: String)
    func logYearInReviewDidTapDonate(slideLoggingID: String)
    func logYearInReviewDidTapShare(slideLoggingID: String)
}

public class WMFYearInReviewViewModel: ObservableObject {
    
    public struct LocalizedStrings {
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, shareText: String, introV3Title: String, introV3Subtitle: String, introV3Footer: String, introV3PrimaryButtonTitle: String, introV3SecondaryButtonTitle: String, wIconAccessibilityLabel: String, wmfLogoImageAccessibilityLabel: String, puzzleGlobeHandAccessibilityLabel: String, puzzleWalkAccessibilityLabel: String, bytesAccessibilityLabel: String, clockAccessibilityLabel: String, stoneAccessibilityLabel: String, compAccessibilityLabel: String, skyAccessibilityLabel: String, duoAccessibilityLabel: String, penballAccessibilityLabel: String, englishReadingSlideTitle: String, englishReadingSlideSubtitle: String, englishTopReadSlideTitle: String, englishTopReadSlideSubtitle: String, englishSavedReadingSlideTitle: String, englishSavedReadingSlideSubtitle: String, englishEditsSlideTitle: String, englishEditsSlideSubtitle: String, englishEditsBytesSlideTitle: String, englishEditsBytesSlideSubtitle: String, collectiveLanguagesSlideTitle: String, collectiveLanguagesSlideSubtitle: String, collectiveArticleViewsSlideTitle: String, collectiveArticleViewsSlideSubtitle: String, collectiveSavedArticlesSlideTitle: String, collectiveSavedArticlesSlideSubtitle: String, collectiveAmountEditsSlideTitle: String, collectiveAmountEditsSlideSubtitle: String, collectiveEditsPerMinuteSlideTitle: String, collectiveEditsPerMinuteSlideSubtitle: String, personalizedYouReadSlideTitleV3: @escaping (Int, Int) -> String, personalizedYouReadSlideSubtitleV3: @escaping (Int) -> String, personalizedDateSlideTitleV3: String, personalizedDateSlideTimeV3: @escaping (Int) -> String, personalizedDateSlideTimeFooterV3: String, personalizedDateSlideDayV3: @escaping (Int) -> String, personalizedDateSlideDayFooterV3: String, personalizedDateSlideMonthV3: @escaping (Int) -> String, personalizedDateSlideMonthFooterV3: String, personalizedSaveCountSlideTitle: @escaping (Int) -> String, personalizedSaveCountSlideSubtitle: @escaping (Int, [String]) -> String, personalizedUserEditsSlideTitle: @escaping (Int) -> String, personzlizedUserEditsSlideSubtitleEN: String, personzlizedUserEditsSlideSubtitleNonEN: String, personalizedYourEditsViewedSlideTitle: @escaping (Int) -> String, personalizedYourEditsViewedSlideSubtitle: @escaping (Int) -> String, personalizedThankYouTitle: String, personalizedThankYouSubtitle: @escaping (String) -> String, personalizedMostReadCategoriesSlideTitle: String, personalizedMostReadCategoriesSlideSubtitle: @escaping ([String]) -> String, personalizedMostReadArticlesSlideTitle: String, personalizedMostReadArticlesSlideSubtitle: @escaping ([String]) -> String, personalizedLocationSlideTitle: @escaping (String) -> String, personalizedLocationSlideSubtitle: @escaping ([String]) -> String, noncontributorTitle: String, noncontributorSubtitle: String, noncontributorButtonText: String, contributorTitle: String, contributorSubtitle: @escaping (Bool, Bool) -> String, contributorGiftTitle: String, contributorGiftSubtitle: String, highlightsSlideTitle: String, highlightsSlideSubtitle: String, highlightsSlideButtonTitle: String, mostReadArticlesTitle: String, minutesReadTitle: String, favoriteReadingDayTitle: String, articlesReadTitle: String, favoriteCategoriesTitle: String, editedArticlesTitle: String, enWikiTopArticlesTitle: String, enWikiTopArticlesValue: [String], hoursSpentReadingTitle: String, hoursSpentReadingValue: String, numberOfChangesMadeTitle: String, numberOfChangesMadeValue: String, numberOfViewedArticlesTitle: String, numberOfViewedArticlesValue: String, numberOfReadingListsTitle: String, numberOfEditsTitle: String, numberOfEditsValue: String, editFrequencyTitle: String, editFrequencyValue: String, logoCaption: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.finishButtonTitle = finishButtonTitle
            self.shareText = shareText
            self.introV3Title = introV3Title
            self.introV3Subtitle = introV3Subtitle
            self.introV3Footer = introV3Footer
            self.introV3PrimaryButtonTitle = introV3PrimaryButtonTitle
            self.introV3SecondaryButtonTitle = introV3SecondaryButtonTitle
            self.wIconAccessibilityLabel = wIconAccessibilityLabel
            self.wmfLogoImageAccessibilityLabel = wmfLogoImageAccessibilityLabel
            self.puzzleGlobeHandAccessibilityLabel = puzzleGlobeHandAccessibilityLabel
            self.puzzleWalkAccessibilityLabel = puzzleWalkAccessibilityLabel
            self.bytesAccessibilityLabel = bytesAccessibilityLabel
            self.clockAccessibilityLabel = clockAccessibilityLabel
            self.stoneAccessibilityLabel = stoneAccessibilityLabel
            self.compAccessibilityLabel = compAccessibilityLabel
            self.skyAccessibilityLabel = skyAccessibilityLabel
            self.duoAccessibilityLabel = duoAccessibilityLabel
            self.penballAccessibilityLabel = penballAccessibilityLabel
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
            self.personalizedYouReadSlideTitleV3 = personalizedYouReadSlideTitleV3
            self.personalizedYouReadSlideSubtitleV3 = personalizedYouReadSlideSubtitleV3
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
            self.mostReadArticlesTitle = mostReadArticlesTitle
            self.minutesReadTitle = minutesReadTitle
            self.favoriteReadingDayTitle = favoriteReadingDayTitle
            self.articlesReadTitle = articlesReadTitle
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
        
        // Intro slides
        let introV3Title: String
        let introV3Subtitle: String
        let introV3Footer: String
        let introV3PrimaryButtonTitle: String
        let introV3SecondaryButtonTitle: String
        
        // Accessibility labels
        let wIconAccessibilityLabel: String
        let wmfLogoImageAccessibilityLabel: String
        
        let puzzleGlobeHandAccessibilityLabel: String
        let puzzleWalkAccessibilityLabel: String
        let bytesAccessibilityLabel: String
        let clockAccessibilityLabel: String
        let stoneAccessibilityLabel: String
        let compAccessibilityLabel: String
        let skyAccessibilityLabel: String
        let duoAccessibilityLabel: String
        let penballAccessibilityLabel: String
        
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
        let personalizedYouReadSlideTitleV3: (Int, Int) -> String
        let personalizedYouReadSlideSubtitleV3: (Int) -> String
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
        let mostReadArticlesTitle: String
        let minutesReadTitle: String
        let favoriteReadingDayTitle: String
        let articlesReadTitle: String
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

    // Highlights
    private var highlightsReadCount: Int?
    private var highlightsFavoriteReadingDay: WMFPageViewDay?
    private var highlightsFrequentCategories: [String]?
    private var highlightsTopReadArticles: [String]?
    private var highlightsMinutesRead: Int?
    private var highlightsEditNumber: Int?
    
    // Donate
    public var toggleAppIcon: (Bool) -> Void
    public var isIconOn: Bool

    @Published public var isLoadingDonate: Bool = false
    
    public var populateYearInReviewReport: () async throws -> Void
    @Published public var isPopulatingReport: Bool = false
    
    private lazy var dataController: WMFYearInReviewDataController? = {
        return try? WMFYearInReviewDataController()
    }()
    
    private let introSlideLoggingID: String
    
    public init(localizedStrings: LocalizedStrings, shareLink: String, hashtag: String, plaintextURL: String, introSlideLoggingID: String,  coordinatorDelegate: YearInReviewCoordinatorDelegate?, loggingDelegate: WMFYearInReviewLoggingDelegate, badgeDelegate: YearInReviewBadgeDelegate?, isUserPermanent: Bool, primaryAppLanguage: WMFProject, toggleAppIcon: @escaping (Bool) -> Void, isIconOn: Bool, populateYearInReviewReport: @escaping () async throws -> Void) {

        self.localizedStrings = localizedStrings
        self.shareLink = shareLink
        self.hashtag = hashtag
        self.plaintextURL = plaintextURL
        self.introSlideLoggingID = introSlideLoggingID
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.badgeDelegate = badgeDelegate
        self.isUserPermanent = isUserPermanent
        self.primaryAppLanguage = primaryAppLanguage
        self.toggleAppIcon = toggleAppIcon
        self.isIconOn = isIconOn
        self.populateYearInReviewReport = populateYearInReviewReport
        
        // Default inits to avoid compiler complaints later in this method
        self.introV3ViewModel = nil
        self.slides = []
        
        self.setupIntro(isUserPermanent: isUserPermanent)
    }
    
    private func prefixedLoggingID(_ suffix: String) -> String {
        let loggedInOrOut = isUserPermanent ? "li" : "lo"
        let enOrNon = primaryAppLanguage.languageCode == "en" ? "en" : "non"
        return "\(loggedInOrOut)_\(enOrNon)_\(suffix)"
    }
    
    // MARK: Personalized Slides
    
    private struct PersonalizedSlides {
        var readCountSlideV3: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlideV3: WMFYearInReviewContributorSlideViewModel?
        var saveCountSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadDateSlideV3: WMFYearInReviewSlideMostReadDateV3ViewModel?
        var viewCountSlide: WMFYearInReviewSlideStandardViewModel?
        var topArticlesSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadCategoriesSlide: WMFYearInReviewSlideStandardViewModel?
        var locationSlide: WMFYearInReviewSlideLocationViewModel?
    }
    
    private func getPersonalizedSlides() -> PersonalizedSlides {
        // Personalized Slides
        var readCountSlideV3: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlideV3: WMFYearInReviewContributorSlideViewModel?
        var saveCountSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadDateSlideV3: WMFYearInReviewSlideMostReadDateV3ViewModel?
        var viewCountSlide: WMFYearInReviewSlideStandardViewModel?
        var topArticlesSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadCategoriesSlide: WMFYearInReviewSlideStandardViewModel?
        var locationSlide: WMFYearInReviewSlideLocationViewModel?

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
                            highlightsMinutesRead = readData.minutesRead
                            highlightsReadCount = readData.readCount

                            readCountSlideV3 = WMFYearInReviewSlideStandardViewModel(
                                gifName: "puzzle-walk",
                                altText: localizedStrings.puzzleWalkAccessibilityLabel,
                                title: localizedStrings.personalizedYouReadSlideTitleV3(readData.readCount, readData.minutesRead),
                                subtitle: localizedStrings.personalizedYouReadSlideSubtitleV3(readData.readCount),
                                subtitleType: .html,
                                loggingID: prefixedLoggingID("readcount"),
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .editCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let editCount = try? decoder.decode(Int.self, from: data),
                           editCount > 0 {
                            highlightsEditNumber = editCount
                            editCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "duo",
                                altText: localizedStrings.duoAccessibilityLabel,
                                title: localizedStrings.personalizedUserEditsSlideTitle(editCount),
                                subtitle: primaryAppLanguage.isEnglishWikipedia ? localizedStrings.personzlizedUserEditsSlideSubtitleEN : localizedStrings.personzlizedUserEditsSlideSubtitleNonEN,
                                loggingID: prefixedLoggingID("editedcount"),
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
                            
                            if donateCount > 0 || editCount > 1 {
                                donateCountSlideV3 = WMFYearInReviewContributorSlideViewModel(
                                    gifName: "contribution-slide",
                                    altText: "",
                                    title: localizedStrings.contributorTitle,
                                    subtitle: localizedStrings.contributorSubtitle(editCount > 0, donateCount > 0),
                                    loggingID: prefixedLoggingID("donoricon"),
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
                                    isIconOn: isIconOn
                                )
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
                            saveCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "sky",
                                altText: localizedStrings.skyAccessibilityLabel,
                                title: localizedStrings.personalizedSaveCountSlideTitle(count),
                                subtitle: localizedStrings.personalizedSaveCountSlideSubtitle(count, savedSlideData.articleTitles),
                                subtitleType: .html,
                                loggingID: prefixedLoggingID("savedcount"),
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
                            highlightsFavoriteReadingDay = mostReadDay
                            
                            mostReadDateSlideV3 = WMFYearInReviewSlideMostReadDateV3ViewModel(
                                gifName: "clock",
                                altText: localizedStrings.clockAccessibilityLabel,
                                title: localizedStrings.personalizedDateSlideTitleV3,
                                time: localizedStrings.personalizedDateSlideTimeV3(mostReadTime.hour),
                                timeFooter: localizedStrings.personalizedDateSlideTimeFooterV3,
                                day: localizedStrings.personalizedDateSlideDayV3(mostReadDay.day),
                                dayFooter: localizedStrings.personalizedDateSlideDayFooterV3,
                                month: localizedStrings.personalizedDateSlideMonthV3(mostReadMonth.month),
                                monthFooter: localizedStrings.personalizedDateSlideMonthFooterV3,
                                loggingID: prefixedLoggingID("readpattern"),
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
                                gifName: "penball",
                                altText: localizedStrings.penballAccessibilityLabel,
                                title: localizedStrings.personalizedYourEditsViewedSlideTitle(viewCount),
                                subtitle: localizedStrings.personalizedYourEditsViewedSlideSubtitle(viewCount),
                                loggingID: prefixedLoggingID("editviewcount"),
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .mostReadCategories:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let mostReadCategories = try? decoder.decode([String].self, from: data), mostReadCategories.count >= 3 {
                            highlightsFrequentCategories = mostReadCategories
                            mostReadCategoriesSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "farms",
                                altText: "",
                                title: localizedStrings.personalizedMostReadCategoriesSlideTitle,
                                subtitle: localizedStrings.personalizedMostReadCategoriesSlideSubtitle(mostReadCategories),
                                subtitleType: .standard,
                                loggingID: prefixedLoggingID("readcategory"),
                                tappedInfo: tappedInfo)
                        }
                    }
                case .topArticles:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let topArticles = try? decoder.decode([String].self, from: data),
                           topArticles.count > 0 {
                            highlightsTopReadArticles = topArticles
                            topArticlesSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "sundial",
                                altText: "",
                                title: localizedStrings.personalizedMostReadArticlesSlideTitle,
                                subtitle: localizedStrings.personalizedMostReadArticlesSlideSubtitle(topArticles),
                                loggingID: prefixedLoggingID("toparticles"),
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
                                loggingID: prefixedLoggingID("readgeo"),
                                tappedInfo: tappedInfo)
                        }
                    }
                }
            }
        }

        return PersonalizedSlides(readCountSlideV3: readCountSlideV3, editCountSlide: editCountSlide, donateCountSlideV3: donateCountSlideV3, saveCountSlide: saveCountSlide, mostReadDateSlideV3: mostReadDateSlideV3, viewCountSlide: viewCountSlide, topArticlesSlide: topArticlesSlide, mostReadCategoriesSlide: mostReadCategoriesSlide, locationSlide: locationSlide)
    }
    
    private func setupIntro(isUserPermanent: Bool) {

        self.isUserPermanent = isUserPermanent

        // Intro slide
        let introV3ViewModel = WMFYearInReviewIntroV3ViewModel(
            gifName: "puzzle-globe-hand",
            altText: localizedStrings.puzzleGlobeHandAccessibilityLabel,
            title: localizedStrings.introV3Title,
            subtitle: localizedStrings.introV3Subtitle,
            footer: localizedStrings.introV3Footer,
            primaryButtonTitle: localizedStrings.introV3PrimaryButtonTitle,
            secondaryButtonTitle: localizedStrings.introV3SecondaryButtonTitle,
            loggingID: self.introSlideLoggingID,
            onAppear: { [weak self] in
                guard let self else { return }
                self.loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: self.introSlideLoggingID)
                self.markFirstSlideAsSeen()
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

    }
    
    private func updateSlides(isUserPermanent: Bool) {

        let bypassLoginForPersonalizedFlow = dataController?.bypassLoginForPersonalizedFlow ?? false

        var slides: [WMFYearInReviewSlide] = []

        let personalizedSlides = getPersonalizedSlides()

        if isUserPermanent || bypassLoginForPersonalizedFlow {
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

            if let donateSlide = personalizedSlides.donateCountSlideV3 {
                // If donateSlide exists, user contributed in some form (donate count > 0 or edit count > 0),
                slides.append(.contribution(donateSlide))
            } else if !shouldHideDonateButtonForCertainRegions() {
                // We want to hide slide entirely for non-donate regions, otherwise add non-contributor version of donate slide.
                slides.append(.contribution(nonContributorSlide))
            }

            if let personalHighlights = getPersonalizedHighlights() {
                slides.append(.highlights(personalHighlights))
            }

        } else {
            slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide))
            slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide))
            slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide))
            slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide))
            slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide))

            if let donateSlide = personalizedSlides.donateCountSlideV3 {
                // If donateSlide exists, user contributed in some form (donate count > 0 or edit count > 0),
                slides.append(.contribution(donateSlide))
            } else if !shouldHideDonateButtonForCertainRegions() {
                // We want to hide slide entirely for non-donate regions, otherwise add non-contributor version of donate slide.
                slides.append(.contribution(nonContributorSlide))
            }

            slides.append(.highlights(primaryAppLanguage.isEnglishWikipedia ? getEnglishCollectiveHighlights() : getCollectiveHighlights()))
        }
        self.slides = slides
    }

    func getPersonalizedHighlights() -> WMFYearInReviewSlideHighlightsViewModel? {
        var itemArray: [TableItem] = []

        if let highlightsTopReadArticles {
            let top3 = highlightsTopReadArticles.prefix(3)
            let articleList = makeNumberedBlueList(Array(top3), needsLinkColor: true)
            let topArticlesItem = TableItem(title: localizedStrings.mostReadArticlesTitle, richRows: articleList)

            itemArray.append(topArticlesItem)
        }

        if let highlightsMinutesRead {
            let timeItem = TableItem(title: localizedStrings.minutesReadTitle, text: String(highlightsMinutesRead))
            itemArray.append(timeItem)
        }

        if let highlightsFavoriteReadingDay {
            let mostReadTimeItem = TableItem(title: localizedStrings.favoriteReadingDayTitle, text: localizedStrings.personalizedDateSlideDayV3(highlightsFavoriteReadingDay.day))
            itemArray.append(mostReadTimeItem)
        }

        if let highlightsReadCount {
            let savedCountItem = TableItem(title: localizedStrings.articlesReadTitle, text: String(highlightsReadCount))
            itemArray.append(savedCountItem)
        }

        if let highlightsFrequentCategories {
            let top3 = highlightsFrequentCategories.prefix(3)
            let categoryList = makeNumberedBlueList(Array(top3), needsLinkColor: false)
            let categoriesItem = TableItem(title: localizedStrings.favoriteCategoriesTitle, richRows: categoryList)
            itemArray.append(categoriesItem)
        }
        
        if let highlightsEditNumber, highlightsEditNumber > 0 {
            let editCountItem = TableItem(title: localizedStrings.editedArticlesTitle, text: String(highlightsEditNumber))
            itemArray.append(editCountItem)
        }
        
        if itemArray.count >= 2 {
            return WMFYearInReviewSlideHighlightsViewModel(
                infoBoxViewModel: WMFInfoboxViewModel(logoCaption: localizedStrings.logoCaption, tableItems: itemArray),
                loggingID: prefixedLoggingID("summary"),
                localizedStrings: getHighlightsStrings(),
                coordinatorDelegate: coordinatorDelegate,
                hashtag: hashtag,
                plaintextURL: plaintextURL,
                tappedShare: tappedShare
            )
        } else {
            return nil
        }
    }

    // MARK: - English Slides

    func getEnglishCollectiveHighlights() -> WMFYearInReviewSlideHighlightsViewModel {
        let articles = localizedStrings.enWikiTopArticlesValue

        let blueList = makeNumberedBlueList(articles, needsLinkColor: true)

        let topArticles = TableItem(title: localizedStrings.enWikiTopArticlesTitle, richRows: blueList)
        let hoursSpent = TableItem(title: localizedStrings.hoursSpentReadingTitle, text: localizedStrings.hoursSpentReadingValue)
        let changesMade = TableItem(title: localizedStrings.numberOfChangesMadeTitle, text: localizedStrings.numberOfChangesMadeValue)
        return WMFYearInReviewSlideHighlightsViewModel(
            infoBoxViewModel: WMFInfoboxViewModel(logoCaption: localizedStrings.logoCaption, tableItems: [topArticles, hoursSpent, changesMade]),
            loggingID: prefixedLoggingID("summary"),
            localizedStrings: getHighlightsStrings(),
            coordinatorDelegate: coordinatorDelegate,
            hashtag: hashtag,
            plaintextURL: plaintextURL,
            tappedShare: tappedShare
        )
    }

    private var englishHoursReadingSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "clock",
            altText: localizedStrings.clockAccessibilityLabel,
            title: localizedStrings.englishReadingSlideTitle,
            subtitle: localizedStrings.englishReadingSlideSubtitle,
            loggingID: prefixedLoggingID("collhours"),
            tappedInfo: tappedInfo
        )
    }
    
    private var englishTopReadSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "comp",
            altText: localizedStrings.compAccessibilityLabel,
            title: localizedStrings.englishTopReadSlideTitle,
            subtitle: localizedStrings.englishTopReadSlideSubtitle,
            subtitleType: .html,
            loggingID: prefixedLoggingID("popular"),
            tappedInfo: tappedInfo
        )
    }
    
    private var englishReadingListSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "sky",
            altText: localizedStrings.skyAccessibilityLabel,
            title: localizedStrings.englishSavedReadingSlideTitle,
            subtitle: localizedStrings.englishSavedReadingSlideSubtitle,
            loggingID: prefixedLoggingID("collrlists"),
            tappedInfo: tappedInfo
        )
    }
    
    private var englishEditsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "duo",
            altText: localizedStrings.duoAccessibilityLabel,
            title: localizedStrings.englishEditsSlideTitle,
            subtitle: localizedStrings.englishEditsSlideSubtitle,
            loggingID: prefixedLoggingID("changes"),
            tappedInfo: tappedInfo
        )
    }
    
    private var englishEditsBytesSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "bytes",
            altText: localizedStrings.bytesAccessibilityLabel,
            title: localizedStrings.englishEditsBytesSlideTitle,
            subtitle: localizedStrings.englishEditsBytesSlideSubtitle,
            subtitleType: .markdown,
            loggingID: prefixedLoggingID("bytes"),
            tappedInfo: tappedInfo
        )
    }

    // MARK: - Collective Slides

    func getCollectiveHighlights() -> WMFYearInReviewSlideHighlightsViewModel {
        let viewedArticles = TableItem(title: localizedStrings.numberOfViewedArticlesTitle, text: localizedStrings.numberOfViewedArticlesValue)
        // let readingLists = TableItem(title: localizedStrings.numberOfReadingListsTitle, text: "987654321")
        let edits = TableItem(title: localizedStrings.numberOfEditsTitle, text: localizedStrings.numberOfEditsValue)
        let editFrequency = TableItem(title: localizedStrings.editFrequencyTitle, text: localizedStrings.editFrequencyValue)
        return WMFYearInReviewSlideHighlightsViewModel(
            infoBoxViewModel: WMFInfoboxViewModel(logoCaption: localizedStrings.logoCaption, tableItems: [viewedArticles, edits, editFrequency]),
            loggingID: prefixedLoggingID("summary"),
            localizedStrings: getHighlightsStrings(),
            coordinatorDelegate: coordinatorDelegate,
            hashtag: hashtag,
            plaintextURL: plaintextURL,
            tappedShare: tappedShare
        )
    }

    private var collectiveLanguagesSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "stone",
            altText: localizedStrings.stoneAccessibilityLabel,
            title: localizedStrings.collectiveLanguagesSlideTitle,
            subtitle: localizedStrings.collectiveLanguagesSlideSubtitle,
            loggingID: prefixedLoggingID("langs"),
            tappedInfo: tappedInfo
        )
    }
    
    private var collectiveArticleViewsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "comp",
            altText: localizedStrings.compAccessibilityLabel,
            title: localizedStrings.collectiveArticleViewsSlideTitle,
            subtitle: localizedStrings.collectiveArticleViewsSlideSubtitle,
            loggingID: prefixedLoggingID("collappread"),
            tappedInfo: tappedInfo
        )
    }

    private var collectiveSavedArticlesSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "sky",
            altText: localizedStrings.skyAccessibilityLabel,
            title: localizedStrings.collectiveSavedArticlesSlideTitle,
            subtitle: localizedStrings.collectiveSavedArticlesSlideSubtitle,
            loggingID: prefixedLoggingID("collrlists"),
            tappedInfo: tappedInfo
        )
    }

    private var collectiveAmountEditsSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "duo",
            altText: localizedStrings.duoAccessibilityLabel,
            title: localizedStrings.collectiveAmountEditsSlideTitle,
            subtitle: localizedStrings.collectiveAmountEditsSlideSubtitle,
            loggingID: prefixedLoggingID("appcolledits"),
            tappedInfo: tappedInfo
        )
    }
    
    private var collectiveEditsPerMinuteSlide: WMFYearInReviewSlideStandardViewModel {
        WMFYearInReviewSlideStandardViewModel(
            gifName: "bytes",
            altText: localizedStrings.bytesAccessibilityLabel,
            title: localizedStrings.collectiveEditsPerMinuteSlideTitle,
            subtitle: localizedStrings.collectiveEditsPerMinuteSlideSubtitle,
            subtitleType: .markdown,
            loggingID: prefixedLoggingID("colleditspm"),
            tappedInfo: tappedInfo
        )
    }
    
    private var nonContributorSlide: WMFYearInReviewContributorSlideViewModel {
        return WMFYearInReviewContributorSlideViewModel(
            gifName: "contribution-slide",
            altText: "",
            title: localizedStrings.noncontributorTitle,
            subtitle: localizedStrings.noncontributorSubtitle,
            loggingID: prefixedLoggingID("nondonoricon"),
            contributionStatus: .noncontributor,
            onTappedDonateButton: { [weak self] in
                self?.handleDonate()
            },
            onInfoButtonTap: tappedInfo,
            donateButtonTitle: localizedStrings.donateButtonTitle,
            toggleButtonTitle: localizedStrings.contributorGiftTitle,
            toggleButtonSubtitle: localizedStrings.contributorGiftSubtitle)
    }
    
    private var currentSlide: WMFYearInReviewSlide {
        return slides[currentSlideIndex]
    }
    
    func tappedIntroV3GetStarted() {
        if !isUserPermanent {
            coordinatorDelegate?.handleYearInReviewAction(.tappedIntroV3GetStartedWhileLoggedOut)
        } else {
            coordinatorDelegate?.handleYearInReviewAction(.tappedIntroV3GetStartedWhileLoggedIn)
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
    
    public func populateReportAndShowFirstSlide() {
        isPopulatingReport = true
        Task { [weak self] in
            guard let self else { return }
            do {
                try await self.populateYearInReviewReport()
                Task { @MainActor [weak self] in
                    
                    guard let self else { return }
                    
                    self.updateSlides(isUserPermanent: isUserPermanent)
                    self.isPopulatingReport = false
                    
                    // Maybe delay a little bit to let slide changes propagate
                    try await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation {
                        self.isShowingIntro = false
                        self.logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
                    }
                }
            } catch {
                Task { @MainActor [weak self] in
                    
                    guard let self else { return }
                    
                    self.updateSlides(isUserPermanent: isUserPermanent)
                    self.isPopulatingReport = false
                    
                    // Maybe delay a little bit to let slide changes propagate
                    try await Task.sleep(nanoseconds: 200_000_000)
                    
                    withAnimation {
                        self.isShowingIntro = false
                        self.logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
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
        case .highlights(let viewModel):
            let view = WMFYearInReviewSlideHighlightShareableView(viewModel: viewModel)
            let renderer = ImageRenderer(content: view)
            renderer.proposedSize = .init(width: 393, height: nil)
            renderer.scale = UIScreen.main.scale
            if let uiImage = renderer.uiImage {
                coordinatorDelegate?.handleYearInReviewAction(.share(image: uiImage))
            }
        }
        logYearInReviewDidTapShare()
    }
    
    func tappedDone() {
        let standardDismissal: () -> Void = { [weak self] in
            guard let self else { return }
            logYearInReviewDidTapDone()
            coordinatorDelegate?.handleYearInReviewAction(.dismiss(hasSeenTwoSlides: hasSeenTwoSlides))
        }

        if !isShowingIntro || isUserPermanent {
            standardDismissal()
        } else {
            logYearInReviewDidTapDone()
            coordinatorDelegate?.handleYearInReviewAction(.tappedIntroV3DoneWhileLoggedOut)
        }
    }
    
    func handleDonate() {
        let getSourceRect: () -> CGRect = { [weak self] in
            return self?.donateButtonRect ?? .zero
        }
        coordinatorDelegate?.handleYearInReviewAction(.donate(getSourceRect: getSourceRect, slideLoggingID: slideLoggingID))
        logYearInReviewDidTapDonate()
    }
    
    private var slideLoggingID: String {
        if isShowingIntro {
            if let introV3ViewModel {
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
    
    var shouldShowTopNavDonateButton: Bool {
        if isShowingIntro {
            return false
        }
        
        // Config has certain countries that do not show donate button
        if shouldHideDonateButtonForCertainRegions() {
            return false
        }
        
        let slide = currentSlide
        switch slide {
        case .contribution(let viewModel):
            if viewModel.contributionStatus == .noncontributor {
                return false
            }
            break
        default:
            break
        }
        
        return true
    }
    
    func tappedLearnMoreAttributedText(url: URL) {
        // TODO: audit this in https://phabricator.wikimedia.org/T406642
        coordinatorDelegate?.handleYearInReviewAction(.learnMoreAttributedText(url: url, shouldShowDonateButton: !shouldHideDonateButtonForCertainRegions(), slideLoggingID: slideLoggingID))
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
        if let dataController {
            dataController.hasSeenYiRIntroSlide = true
            badgeDelegate?.updateYIRBadgeVisibility()
        }
    }

    func tappedInfo() {
        switch currentSlide {
        case .standard:
            coordinatorDelegate?.handleYearInReviewAction(.info)
        case .mostReadDateV3:
            coordinatorDelegate?.handleYearInReviewAction(.info)
        case .location:
            coordinatorDelegate?.handleYearInReviewAction(.info)
        case .contribution:
            coordinatorDelegate?.handleYearInReviewAction(.info)
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
