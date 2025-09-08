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
        let personzlizedUserEditsSlideSubtitle: (Int) -> String
        let personzlizedUserEditsSlideSubtitle500Plus: String
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

        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, shareText: String, introV2Title: String, introV2TitlePersonalized: String, introV2Subtitle: String, introV2SubtitlePersonzalized: String, introV2PrimaryButtonTitle: String, introV2SecondaryButtonTitle: String, introV3Title: String, introV3Subtitle: String, introV3Footer: String, introV3PrimaryButtonTitle: String, introV3SecondaryButtonTitle: String, wIconAccessibilityLabel: String, wmfLogoImageAccessibilityLabel: String, personalizedExploreAccessibilityLabel: String, personalizedYouReadAccessibilityLabel: String, personalizedUserEditsAccessibilityLabel: String, personalizedDonationThankYouAccessibilityLabel: String, personalizedSavedArticlesAccessibilityLabel: String, personalizedWeekdayAccessibilityLabel: String, personalizedYourEditsViewsAccessibilityLabel: String, collectiveExploreAccessibilityLabel: String, collectiveLanguagesAccessibilityLabel: String, collectiveArticleViewsAccessibilityLabel: String, collectiveSavedArticlesAccessibilityLabel: String, collectiveAmountEditsAccessibilityLabel: String, englishEditsAccessibilityLabel: String, collectiveEditsPerMinuteAccessibilityLabel: String, collectiveZeroAdsAccessibilityLabel: String, englishReadingSlideTitle: String, englishReadingSlideSubtitle: String, englishTopReadSlideTitle: String, englishTopReadSlideSubtitle: String, englishSavedReadingSlideTitle: String, englishSavedReadingSlideSubtitle: String, englishEditsSlideTitle: String, englishEditsSlideSubtitle: String, englishEditsBytesSlideTitle: String, englishEditsBytesSlideSubtitle: String, collectiveLanguagesSlideTitle: String, collectiveLanguagesSlideSubtitle: String, collectiveArticleViewsSlideTitle: String, collectiveArticleViewsSlideSubtitle: String, collectiveSavedArticlesSlideTitle: String, collectiveSavedArticlesSlideSubtitle: String, collectiveAmountEditsSlideTitle: String, collectiveAmountEditsSlideSubtitle: String, collectiveEditsPerMinuteSlideTitle: String, collectiveEditsPerMinuteSlideSubtitle: String, collectiveZeroAdsSlideTitle: String, collectiveZeroAdsSlideSubtitle: @escaping () -> String, personalizedYouReadSlideTitleV2: @escaping (Int) -> String, personalizedYouReadSlideSubtitleV2: @escaping (Int) -> String, personalizedDateSlideTitleV2: @escaping (Int) -> String, personalizedDateSlideSubtitleV2: @escaping (Int) -> String, personalizedDateSlideTitleV3: String, personalizedDateSlideTimeV3: @escaping (Int) -> String, personalizedDateSlideTimeFooterV3: String, personalizedDateSlideDayV3: @escaping (Int) -> String, personalizedDateSlideDayFooterV3: String, personalizedDateSlideMonthV3: @escaping (Int) -> String, personalizedDateSlideMonthFooterV3: String, personalizedSaveCountSlideTitle: @escaping (Int) -> String, personalizedSaveCountSlideSubtitle: @escaping (Int, [String]) -> String, personalizedUserEditsSlideTitle: @escaping (Int) -> String, personzlizedUserEditsSlideTitle500Plus: String, personzlizedUserEditsSlideSubtitle: @escaping (Int) -> String, personzlizedUserEditsSlideSubtitle500Plus: String, personalizedYourEditsViewedSlideTitle: @escaping (Int) -> String, personalizedYourEditsViewedSlideSubtitle: @escaping (Int) -> String, personalizedThankYouTitle: String, personalizedThankYouSubtitle: @escaping (String) -> String, personalizedMostReadCategoriesSlideTitle: String, personalizedMostReadCategoriesSlideSubtitle: @escaping ([String]) -> String, personalizedMostReadArticlesSlideTitle: String, personalizedMostReadArticlesSlideSubtitle: @escaping ([String]) -> String, personalizedLocationSlideTitle: @escaping (String) -> String, personalizedLocationSlideSubtitle: @escaping ([String]) -> String) {
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
            self.personzlizedUserEditsSlideSubtitle = personzlizedUserEditsSlideSubtitle
            self.personzlizedUserEditsSlideSubtitle500Plus = personzlizedUserEditsSlideSubtitle500Plus
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
        }
    }
    
    @Published var currentSlideIndex = 0 {
        didSet {
            logSlideAppearance()
            if currentSlideIndex == 1 {
                hasSeenTwoSlides = true
            }
        }
    }
    @Published var isShowingIntro: Bool = true
    
    public let localizedStrings: LocalizedStrings
    
    private(set) var introV2ViewModel: WMFYearInReviewIntroV2ViewModel?
    private(set) var introV3ViewModel: WMFYearInReviewIntroV3ViewModel?
    
    private(set) var slides: [WMFYearInReviewSlide] // doesn't include intro
    public let shareLink: String
    public let hashtag: String
    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    private weak var badgeDelegate: YearInReviewBadgeDelegate?
    private(set) weak var loggingDelegate: WMFYearInReviewLoggingDelegate?
    private var hasSeenTwoSlides: Bool = false
    
    private var isUserPermanent: Bool // i.e. logged in
    private let primaryAppLanguage: WMFProject
    private let aboutYiRURL: URL?
    private var hasPersonalizedDonateSlide: Bool
    
    @Published public var isLoading: Bool = false
    
    public init(localizedStrings: LocalizedStrings, shareLink: String, hashtag: String, coordinatorDelegate: YearInReviewCoordinatorDelegate?, loggingDelegate: WMFYearInReviewLoggingDelegate, badgeDelegate: YearInReviewBadgeDelegate?, isUserPermanent: Bool, aboutYiRURL: URL?, primaryAppLanguage: WMFProject) {
        self.localizedStrings = localizedStrings
        self.shareLink = shareLink
        self.hashtag = hashtag
        self.coordinatorDelegate = coordinatorDelegate
        self.loggingDelegate = loggingDelegate
        self.badgeDelegate = badgeDelegate
        self.isUserPermanent = isUserPermanent
        self.primaryAppLanguage = primaryAppLanguage
        self.aboutYiRURL = aboutYiRURL
        
        // Default inits to avoid compiler complaints later in this method
        self.introV2ViewModel = nil
        self.introV3ViewModel = nil
        self.slides = []
        self.hasPersonalizedDonateSlide = false
        
        self.updateSlides(isUserPermanent: isUserPermanent)
    }
    
    // MARK: Personalized Slides
    
    private struct PersonalizedSlides {
        var readCountSlideV2: WMFYearInReviewSlideStandardViewModel?
        var readCountSlideV3: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlide: WMFYearInReviewSlideStandardViewModel?
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
        var donateCountSlide: WMFYearInReviewSlideStandardViewModel?
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
                                title: localizedStrings.personalizedYouReadSlideTitleV2(readData.readCount),
                                subtitle: localizedStrings.personalizedYouReadSlideSubtitleV2(readData.readCount),
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
                            editCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-04",
                                altText: localizedStrings.personalizedUserEditsAccessibilityLabel,
                                title: editCount >= 500 ? localizedStrings.personzlizedUserEditsSlideTitle500Plus : localizedStrings.personalizedUserEditsSlideTitle(editCount),
                                subtitle: editCount >= 500 ? localizedStrings.personzlizedUserEditsSlideSubtitle500Plus : localizedStrings.personzlizedUserEditsSlideSubtitle(editCount),
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
                        if let donateCount = try? decoder.decode(Int.self, from: data),
                           donateCount > 0 {
                            
                            donateCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "all-slide-06",
                                altText: localizedStrings.personalizedDonationThankYouAccessibilityLabel,
                                title: localizedStrings.personalizedThankYouTitle,
                                subtitle: localizedStrings.personalizedThankYouSubtitle(primaryAppLanguage.languageCode ?? "en"),
                                subtitleType: .markdown,
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: true,
                                loggingID: "thank_custom",
                                tappedLearnMore: tappedLearnMore(url:),
                                tappedInfo: tappedInfo
                            )
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
                        if let mostReadCategories = try? decoder.decode([String].self, from: data),
                           mostReadCategories.count >= 5 { // TODO: confirm we don't show slide at all if categories < 5?
                            
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

        return PersonalizedSlides(readCountSlideV2: readCountSlideV2, readCountSlideV3: readCountSlideV3, editCountSlide: editCountSlide, donateCountSlide: donateCountSlide, saveCountSlide: saveCountSlide, mostReadDateSlideV2: mostReadDateSlideV2, mostReadDateSlideV3: mostReadDateSlideV3, viewCountSlide: viewCountSlide, topArticlesSlide: topArticlesSlide, mostReadCategoriesSlide: mostReadCategoriesSlide, locationSlide: locationSlide)
    }
    
    public func updateSlides(isUserPermanent: Bool) {
        
        var slides: [WMFYearInReviewSlide] = []
        
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
        
        let personalizedSlides = getPersonalizedSlides(aboutYiRURL: aboutYiRURL)
        
        if WMFDeveloperSettingsDataController.shared.showYiRV3 { // TODO: Confirm ordering / fallbacks are correct once product requirements are finalized.
            if isUserPermanent {
                slides.append(.standard(personalizedSlides.readCountSlideV3 ?? (primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide)))
                
                if let mostReadDateSlideV3 = personalizedSlides.mostReadDateSlideV3 {
                    slides.append(.mostReadDateV3(mostReadDateSlideV3))
                } else {
                    slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide))
                }
                
                if let categorySlide = personalizedSlides.mostReadCategoriesSlide {
                    slides.append(.standard(categorySlide))
                }
                
                if let locationSlide = personalizedSlides.locationSlide {
                    slides.append(.location(locationSlide))
                }
                
                if let topArticlesSlide = personalizedSlides.topArticlesSlide {
                    slides.append(.standard(topArticlesSlide))
                }
                
                slides.append(.standard(personalizedSlides.saveCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide)))
                slides.append(.standard(personalizedSlides.editCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide)))
                slides.append(.standard(personalizedSlides.viewCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide)))
                slides.append(.standard(personalizedSlides.donateCountSlide ?? collectiveZeroAdsSlide))
            } else {
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide))
                slides.append(.standard(personalizedSlides.donateCountSlide ?? collectiveZeroAdsSlide))
            }
        } else if WMFDeveloperSettingsDataController.shared.showYiRV2 {
            if isUserPermanent {
                slides.append(.standard(personalizedSlides.readCountSlideV2 ?? (primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide)))
                slides.append(.standard(personalizedSlides.mostReadDateSlideV2 ?? (primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide)))
                slides.append(.standard(personalizedSlides.saveCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide)))
                slides.append(.standard(personalizedSlides.editCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide)))
                slides.append(.standard(personalizedSlides.viewCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide)))
                slides.append(.standard(personalizedSlides.donateCountSlide ?? collectiveZeroAdsSlide))
            } else {
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishReadingListSlide : collectiveSavedArticlesSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsSlide : collectiveAmountEditsSlide))
                slides.append(.standard(primaryAppLanguage.isEnglishWikipedia ? englishEditsBytesSlide : collectiveEditsPerMinuteSlide))
                slides.append(.standard(personalizedSlides.donateCountSlide ?? collectiveZeroAdsSlide))
            }
        }
        
        self.slides = slides
        
        if personalizedSlides.donateCountSlide != nil {
            self.hasPersonalizedDonateSlide = true
        }
    }
    
    // MARK: English Slides
    
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
    
    // MARK: Collective Slides
    
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
    
    private var currentSlide: WMFYearInReviewSlide {
        return slides[currentSlideIndex]
    }
    
    func tappedIntroV2GetStarted() {
        loggingDelegate?.logYearInReviewIntroDidTapContinue()
        isShowingIntro = false
        logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
    }
    
    func tappedIntroV3GetStarted() {
        if !isUserPermanent {
            coordinatorDelegate?.handleYearInReviewAction(.tappedIntroV3GetStartedWhileLoggedOut)
        } else {
            loggingDelegate?.logYearInReviewIntroDidTapContinue()
            isShowingIntro = false
            logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
        }
    }
    
    public func tappedIntroV3LoginPromptNoThanks() {
        withAnimation {
            isShowingIntro = false
        }
        
        logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
    }
    
    public func tappedIntroV3ExitConfirmationGetStarted() {
        withAnimation {
            isShowingIntro = false
        }
        
        logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
    }
    
    public func completedLoginFromIntroV3LoginPrompt() {
        withAnimation {
            isShowingIntro = false
        }
        
        logSlideAppearance() // Manually logs appearance of first slide (currentSlideIndex is already set to 0)
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
            let view = WMFYearInReviewSlideStandardShareableView(viewModel: viewModel, hashtag: hashtag)
            let shareView = view.snapshot()
            coordinatorDelegate?.handleYearInReviewAction(.share(image: shareView))
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
    
    func handleDonate(sourceRect: CGRect) {
        coordinatorDelegate?.handleYearInReviewAction(.donate(sourceRect: sourceRect))
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
        case .mostReadDateV3(let viewModel):
            return viewModel.loggingID
        }
    }
    
    var shouldShowDonateButton: Bool {
        if isShowingIntro {
            return false
        }
        
        let slide = currentSlide
        switch slide {
        case .standard(let viewModel):
            if viewModel.forceHideDonateButton {
                return false
            } else if let shouldHide = try? WMFYearInReviewDataController().shouldHideDonateButton() {
                    return !shouldHide
            } else {
                return true
            }
        case .location:
            return true
        case .mostReadDateV3:
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
}

enum WMFYearInReviewSlide {
    case standard(WMFYearInReviewSlideStandardViewModel)
    case location(WMFYearInReviewSlideLocationViewModel)
    case mostReadDateV3(WMFYearInReviewSlideMostReadDateV3ViewModel)
    // todo: articles read
}

@objc public protocol YearInReviewBadgeDelegate: AnyObject {
    @objc func updateYIRBadgeVisibility()
}

private extension WMFProject {
    var isEnglishWikipedia: Bool {
        switch self {
        case .wikipedia(let language):
            return language.languageCode.lowercased() == "en"
        default:
            return false
        }
    }
}
