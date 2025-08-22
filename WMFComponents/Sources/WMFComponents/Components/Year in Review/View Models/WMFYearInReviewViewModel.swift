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
        let introTitle: String
        let introTitlePersonalized: String
        let introSubtitle: String
        let introSubtitlePersonzalized: String
        let introPrimaryButtonTitle: String
        let introSecondaryButtonTitle: String
        
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
        let personalizedYouReadSlideTitle: (Int) -> String
        let personalizedYouReadSlideSubtitle: (Int) -> String
        let personalizedDaySlideTitle: (Int) -> String
        let personalizedDaySlideSubtitle: (Int) -> String
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
        
        // Location Slide Strings
        let locationTitle: String
        
        public init(donateButtonTitle: String, doneButtonTitle: String, shareButtonTitle: String, nextButtonTitle: String, finishButtonTitle: String, shareText: String, introTitle: String, introTitlePersonalized: String, introSubtitle: String, introSubtitlePersonzalized: String, introPrimaryButtonTitle: String, introSecondaryButtonTitle: String, wIconAccessibilityLabel: String, wmfLogoImageAccessibilityLabel: String, personalizedExploreAccessibilityLabel: String, personalizedYouReadAccessibilityLabel: String, personalizedUserEditsAccessibilityLabel: String, personalizedDonationThankYouAccessibilityLabel: String, personalizedSavedArticlesAccessibilityLabel: String, personalizedWeekdayAccessibilityLabel: String, personalizedYourEditsViewsAccessibilityLabel: String, collectiveExploreAccessibilityLabel: String, collectiveLanguagesAccessibilityLabel: String, collectiveArticleViewsAccessibilityLabel: String, collectiveSavedArticlesAccessibilityLabel: String, collectiveAmountEditsAccessibilityLabel: String, englishEditsAccessibilityLabel: String, collectiveEditsPerMinuteAccessibilityLabel: String, collectiveZeroAdsAccessibilityLabel: String, englishReadingSlideTitle: String, englishReadingSlideSubtitle: String, englishTopReadSlideTitle: String, englishTopReadSlideSubtitle: String, englishSavedReadingSlideTitle: String, englishSavedReadingSlideSubtitle: String, englishEditsSlideTitle: String, englishEditsSlideSubtitle: String, englishEditsBytesSlideTitle: String, englishEditsBytesSlideSubtitle: String, collectiveLanguagesSlideTitle: String, collectiveLanguagesSlideSubtitle: String, collectiveArticleViewsSlideTitle: String, collectiveArticleViewsSlideSubtitle: String, collectiveSavedArticlesSlideTitle: String, collectiveSavedArticlesSlideSubtitle: String, collectiveAmountEditsSlideTitle: String, collectiveAmountEditsSlideSubtitle: String, collectiveEditsPerMinuteSlideTitle: String, collectiveEditsPerMinuteSlideSubtitle: String, collectiveZeroAdsSlideTitle: String, collectiveZeroAdsSlideSubtitle: @escaping () -> String, personalizedYouReadSlideTitle: @escaping (Int) -> String, personalizedYouReadSlideSubtitle: @escaping (Int) -> String, personalizedDaySlideTitle: @escaping (Int) -> String, personalizedDaySlideSubtitle: @escaping (Int) -> String, personalizedSaveCountSlideTitle: @escaping (Int) -> String, personalizedSaveCountSlideSubtitle: @escaping (Int, [String]) -> String, personalizedUserEditsSlideTitle: @escaping (Int) -> String, personzlizedUserEditsSlideTitle500Plus: String, personzlizedUserEditsSlideSubtitle: @escaping (Int) -> String, personzlizedUserEditsSlideSubtitle500Plus: String, personalizedYourEditsViewedSlideTitle: @escaping (Int) -> String, personalizedYourEditsViewedSlideSubtitle: @escaping (Int) -> String, personalizedThankYouTitle: String, personalizedThankYouSubtitle: @escaping (String) -> String, locationTitle: String) {
            self.donateButtonTitle = donateButtonTitle
            self.doneButtonTitle = doneButtonTitle
            self.shareButtonTitle = shareButtonTitle
            self.nextButtonTitle = nextButtonTitle
            self.finishButtonTitle = finishButtonTitle
            self.shareText = shareText
            self.introTitle = introTitle
            self.introTitlePersonalized = introTitlePersonalized
            self.introSubtitle = introSubtitle
            self.introSubtitlePersonzalized = introSubtitlePersonzalized
            self.introPrimaryButtonTitle = introPrimaryButtonTitle
            self.introSecondaryButtonTitle = introSecondaryButtonTitle
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
            self.personalizedYouReadSlideTitle = personalizedYouReadSlideTitle
            self.personalizedYouReadSlideSubtitle = personalizedYouReadSlideSubtitle
            self.personalizedDaySlideTitle = personalizedDaySlideTitle
            self.personalizedDaySlideSubtitle = personalizedDaySlideSubtitle
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
            self.locationTitle = locationTitle
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
    
    private(set) var introViewModel: WMFYearInReviewIntroViewModel?
    private(set) var slides: [WMFYearInReviewSlide] // doesn't include intro
    public let shareLink: String
    public let hashtag: String
    private weak var coordinatorDelegate: YearInReviewCoordinatorDelegate?
    private weak var badgeDelegate: YearInReviewBadgeDelegate?
    private(set) weak var loggingDelegate: WMFYearInReviewLoggingDelegate?
    private var hasSeenTwoSlides: Bool = false
    
    private let isUserPermanent: Bool // i.e. logged in
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
        self.introViewModel = nil
        self.slides = []
        self.hasPersonalizedDonateSlide = false
        
        // Create slide view models
        
        // Intro slide
        let introLoggingID = isUserPermanent ? "start_c" : "start"
        let introViewModel = WMFYearInReviewIntroViewModel(
            gifName: isUserPermanent ? "personal-slide-00" : "english-slide-00",
            altText: isUserPermanent ? localizedStrings.personalizedExploreAccessibilityLabel : localizedStrings.collectiveExploreAccessibilityLabel,
            title: isUserPermanent ? localizedStrings.introTitlePersonalized : localizedStrings.introTitle,
            subtitle: isUserPermanent ? localizedStrings.introSubtitlePersonzalized : localizedStrings.introSubtitle,
            primaryButtonTitle: localizedStrings.introPrimaryButtonTitle,
            secondaryButtonTitle: localizedStrings.introSecondaryButtonTitle,
            loggingID: introLoggingID,
            onAppear: { [weak self] in
                self?.loggingDelegate?.logYearInReviewSlideDidAppear(slideLoggingID: introLoggingID)
                self?.markFirstSlideAsSeen()
            },
            tappedPrimaryButton: { [weak self] in
                self?.tappedGetStarted()
            },
            tappedSecondaryButton: { [weak self] in
                self?.loggingDelegate?.logYearInReviewIntroDidTapLearnMore()
                self?.coordinatorDelegate?.handleYearInReviewAction(.introLearnMore)
            }
        )
        self.introViewModel = introViewModel
        
        let personalizedSlides = getPersonalizedSlides(aboutYiRURL: aboutYiRURL)
        if isUserPermanent {
            slides.append(.standard(personalizedSlides.readCountSlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishHoursReadingSlide : collectiveLanguagesSlide)))
            slides.append(.standard(personalizedSlides.mostReadDaySlide ?? (primaryAppLanguage.isEnglishWikipedia ? englishTopReadSlide : collectiveArticleViewsSlide)))
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
        
        if personalizedSlides.donateCountSlide != nil {
            self.hasPersonalizedDonateSlide = true
        }
        
        // Add a quick fake location slide
        let fakeLocation = WMFYearInReviewSlideLocationViewModel(localizedStrings: localizedStrings, loggingID: "")
        slides.append(.location(fakeLocation))
    }
    
    // MARK: Personalized Slides
    
    private struct PersonalizedSlides {
        var readCountSlide: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlide: WMFYearInReviewSlideStandardViewModel?
        var saveCountSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadDaySlide: WMFYearInReviewSlideStandardViewModel?
        var viewCountSlide: WMFYearInReviewSlideStandardViewModel?
    }
    
    private func getPersonalizedSlides(aboutYiRURL: URL?) -> PersonalizedSlides {
        // Personalized Slides
        var readCountSlide: WMFYearInReviewSlideStandardViewModel?
        var editCountSlide: WMFYearInReviewSlideStandardViewModel?
        var donateCountSlide: WMFYearInReviewSlideStandardViewModel?
        var saveCountSlide: WMFYearInReviewSlideStandardViewModel?
        var mostReadDaySlide: WMFYearInReviewSlideStandardViewModel?
        var viewCountSlide: WMFYearInReviewSlideStandardViewModel?
        
        let dataController = try? WMFYearInReviewDataController()
        
        // Fetch YiR report for personalized data, assign to personalized slides
        if let dataController,
           let report = try? dataController.fetchYearInReviewReport(forYear: WMFYearInReviewDataController.targetYear) {
            for slide in report.slides {
                switch slide.id {
                case .readCount:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let readCount = try? decoder.decode(Int.self, from: data),
                           readCount > 5 {
                            readCountSlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-01",
                                altText: localizedStrings.personalizedYouReadAccessibilityLabel,
                                title: localizedStrings.personalizedYouReadSlideTitle(readCount),
                                subtitle: localizedStrings.personalizedYouReadSlideSubtitle(readCount),
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
                                infoURL: aboutYiRURL,
                                forceHideDonateButton: false,
                                loggingID: "save_count_custom",
                                tappedInfo: tappedInfo
                            )
                        }
                    }
                case .mostReadDay:
                    if let data = slide.data {
                        let decoder = JSONDecoder()
                        if let mostReadDay = try? decoder.decode(WMFPageViewDay.self, from: data),
                           mostReadDay.getViewCount() > 0 {
                            
                            mostReadDaySlide = WMFYearInReviewSlideStandardViewModel(
                                gifName: "personal-slide-02",
                                altText: localizedStrings.personalizedWeekdayAccessibilityLabel,
                                title: localizedStrings.personalizedDaySlideTitle(mostReadDay.getDay()),
                                subtitle: localizedStrings.personalizedDaySlideSubtitle(mostReadDay.getDay()),
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
                }
            }
        }
        
        return PersonalizedSlides(readCountSlide: readCountSlide, editCountSlide: editCountSlide, donateCountSlide: donateCountSlide, saveCountSlide: saveCountSlide, mostReadDaySlide: mostReadDaySlide, viewCountSlide: viewCountSlide)
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
    
    func tappedGetStarted() {
        loggingDelegate?.logYearInReviewIntroDidTapContinue()
        isShowingIntro = false
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

    func tappedShare() {
        switch currentSlide {
        case .standard(let viewModel):
            let view = WMFYearInReviewSlideStandardShareableView(viewModel: viewModel, hashtag: hashtag)
            let shareView = view.snapshot()
            coordinatorDelegate?.handleYearInReviewAction(.share(image: shareView))
        case .location:
            break
            // todo:
        }
        logYearInReviewDidTapShare()
    }
    
    func tappedShareAll() {
        
    }
    
    func tappedDone() {
        logYearInReviewDidTapDone()
        coordinatorDelegate?.handleYearInReviewAction(.dismiss(hasSeenTwoSlides: hasSeenTwoSlides))
    }
    
    func handleDonate(sourceRect: CGRect) {
        coordinatorDelegate?.handleYearInReviewAction(.donate(sourceRect: sourceRect))
        logYearInReviewDidTapDonate()
    }
    
    private var slideLoggingID: String {
        if isShowingIntro,
           let introViewModel {
            return introViewModel.loggingID
        }
        switch currentSlide {
        case .standard(let viewModel):
            return viewModel.loggingID
        case .location(let viewModel):
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
        case .location:
            // info button not yet on location
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
}

enum WMFYearInReviewSlide {
    case standard(WMFYearInReviewSlideStandardViewModel)
    case location(WMFYearInReviewSlideLocationViewModel)
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
