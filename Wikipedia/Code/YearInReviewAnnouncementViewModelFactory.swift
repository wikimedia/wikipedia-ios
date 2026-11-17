import WMF
import WMFComponents
import WMFData
import WMFNativeLocalizations

/// Builds the Year in Review announcement screen and the text on it, so the coordinator only has to
/// present the result. Also owns the copy of the log in prompt that follows the announcement, because
/// it shares its low data text with the announcement.
struct YearInReviewAnnouncementViewModelFactory {

    typealias DataState = WMFYearInReviewDataController.YiRDataState

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

    @MainActor
    func makeViewModel(dataState: DataState, readingDayCount: Int, delegate: WMFYearInReviewAnnouncementDelegate) -> WMFYearInReviewAnnouncementViewModel {
        let localizedStrings = makeLocalizedStrings(dataState: dataState, readingDayCount: readingDayCount)

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
            delegate: delegate
        )
    }

    func makeLocalizedStrings(dataState: DataState, readingDayCount: Int) -> WMFYearInReviewAnnouncementViewModel.LocalizedStrings {
        let headline: String
        let body: String
        switch dataState {
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
            closeButtonAccessibilityLabel: CommonStrings.closeButtonAccessibilityLabel,
            moreButtonAccessibilityLabel: CommonStrings.moreButton,
            learnMoreButtonTitle: CommonStrings.learnMoreTitle(),
            aboutInsightsButtonTitle: YearInReviewSlideViewModelFactory.aboutInsightsButtonTitle,
            shareFeedbackButtonTitle: CommonStrings.shareFeedbackTitle
        )
    }

    /// The text of the prompt shown to logged-out readers after they tap Explore on the announcement.
    func makeLoginPromptCopy(dataState: DataState) -> (title: String, message: String) {
        switch dataState {
        case .dataRich:
            let title = WMFLocalizedString("year-in-review-2026-announcement-login-personalized-title", value: "Your Year in Review is best with an account", comment: "Title of the prompt shown to logged-out readers with enough reading data after they tap Explore on the Year in Review announcement.")
            let message = WMFLocalizedString("year-in-review-2026-announcement-login-personalized-message", value: "Log in to see your top topics, articles, longest rabbit hole, and more. You can still see collective insights without logging in.", comment: "Message of the prompt shown to logged-out readers with enough reading data after they tap Explore on the Year in Review announcement.")
            return (title, message)
        case .lowData:
            return (CommonStrings.yearInReviewLoginPromptCollectiveTitle, CommonStrings.yearInReviewLoginPromptCollectiveMessage)
        }
    }
}
