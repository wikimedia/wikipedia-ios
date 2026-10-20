import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Builds the Year in Review announcement screen and the text on it, so the coordinator only has to
/// present the result. Also owns the copy of the log in prompt that follows the announcement, because
/// it shares its low data text with the announcement.
struct YearInReviewAnnouncementViewModelFactory {

    typealias UserDataState = WMFYearInReviewDataController.YiRUserDataState

    /// The announcement uses the cover artboard of the templates file.
    static let animation = WMFRiveAnimation(
        resourceName: "all_templates",
        artboardName: "cover",
        stateMachineName: "cover-statemachine"
    )

    /// Text fields on the cover's `DataTemplate` view model. `headline` and `data` are not used.
    enum CoverTextPath {
        static let title = WMFRiveText(path: "coverTitle")
        static let body = WMFRiveText(path: "bodyCopy")
    }

    /// The cover sets this flag for the contrast of the controls above it, the same as each slide.
    static let lightContentFlag = WMFRiveBool(path: "isUIWhite")

    /// The title and the body copy grow, so long copy can push the content past the bottom of the
    /// cover. Over these line counts, make both smaller by the same scale, to at most
    /// `YearInReviewSlideViewModelFactory.copyMinimumScale`. Same rule as the copy on the slides.
    static let textFits: [WMFRiveTextFit] = [
        WMFRiveTextFit(
            text: CoverTextPath.title,
            fontAssetName: "SanSerifFont",
            maximumWidth: coverTitleWidth,
            maximumLines: 3,
            minimumScale: YearInReviewSlideViewModelFactory.copyMinimumScale,
            group: "copy",
            globalViewModelName: "GlobalProperties",
            fontSize: WMFRiveNumber(path: "coverGlyphsFontSize"),
            lineHeight: WMFRiveNumber(path: "coverGlyphsLineHeight")
        ),
        WMFRiveTextFit(
            text: CoverTextPath.body,
            fontAssetName: "SerifFont",
            maximumWidth: coverBodyWidth,
            maximumLines: 5,
            minimumScale: YearInReviewSlideViewModelFactory.copyMinimumScale,
            group: "copy",
            globalViewModelName: "GlobalProperties",
            fontSize: WMFRiveNumber(path: "bodyCopyFontSize"),
            lineHeight: WMFRiveNumber(path: "bodyCopyLineHeight")
        )
    ]

    /// In artboard units. The title box is a little wider than this. The body box is narrower, but
    /// a smaller width would make the English collective body (5 lines) smaller too. The cover has a
    /// lot of free space below the body, so a body that wraps to a few more lines still fits.
    /// Checked with long Russian copy (October 2026): the title made both smaller, to 3 lines.
    private static let coverTitleWidth = 290.0
    private static let coverBodyWidth = 290.0

    @MainActor
    func makeViewModel(userDataState: UserDataState, readingDayCount: Int, delegate: WMFYearInReviewAnnouncementDelegate) -> WMFYearInReviewAnnouncementViewModel {
        let localizedStrings = makeLocalizedStrings(userDataState: userDataState, readingDayCount: readingDayCount)

        return WMFYearInReviewAnnouncementViewModel(
            animation: Self.animation,
            riveText: [
                // The title is shown in capitals. VoiceOver still gets it as written, from
                // `animationAccessibilityLabel`.
                CoverTextPath.title: localizedStrings.animationAccessibilityLabel.localizedUppercase,
                CoverTextPath.body: localizedStrings.body
            ],
            localizedStrings: localizedStrings,
            lightContentFlag: Self.lightContentFlag,
            textFits: Self.textFits,
            delegate: delegate
        )
    }

    func makeLocalizedStrings(userDataState: UserDataState, readingDayCount: Int) -> WMFYearInReviewAnnouncementViewModel.LocalizedStrings {
        let headline: String
        let body: String
        switch userDataState {
        case .dataRich:
            headline = CommonStrings.yearInReviewIntroTitle
            body = CommonStrings.yearInReviewIntroSubtitle(dayCount: readingDayCount)
        case .lowData:
            headline = CommonStrings.yearInReviewCollectiveIntroTitle
            body = CommonStrings.yearInReviewCollectiveIntroSubtitle
        }

        return WMFYearInReviewAnnouncementViewModel.LocalizedStrings(
            animationAccessibilityLabel: headline,
            body: body,
            exploreButtonTitle: WMFLocalizedString("year-in-review-2026-announcement-explore", value: "Explore", comment: "Title of the button on the Year in Review announcement that opens Year in Review."),
            wIconAccessibilityLabel: CommonStrings.plainWikipediaName,
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: CommonStrings.moreButton,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            aboutInsightsButtonTitle: YearInReviewSlideViewModelFactory.aboutInsightsButtonTitle,
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle
        )
    }

    /// The text of the prompt shown to logged-out readers after they tap Explore on the announcement.
    func makeLoginPromptCopy(userDataState: UserDataState) -> (title: String, message: String) {
        switch userDataState {
        case .dataRich:
            let title = WMFLocalizedString("year-in-review-2026-announcement-login-personalized-title", value: "Your Year in Review is best with an account", comment: "Title of the prompt shown to logged-out readers with enough reading data after they tap Explore on the Year in Review announcement.")
            let message = WMFLocalizedString("year-in-review-2026-announcement-login-personalized-message", value: "Log in to see your top topics, articles, longest rabbit hole, and more. You can still see collective insights without logging in.", comment: "Message of the prompt shown to logged-out readers with enough reading data after they tap Explore on the Year in Review announcement.")
            return (title, message)
        case .lowData:
            return (CommonStrings.yearInReviewLoginPromptCollectiveTitle, CommonStrings.yearInReviewLoginPromptCollectiveMessage)
        }
    }
}
