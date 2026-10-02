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

    @MainActor
    func makeViewModel(userDataState: UserDataState, readingDayCount: Int, delegate: WMFYearInReviewAnnouncementDelegate) -> WMFYearInReviewAnnouncementViewModel {
        let localizedStrings = makeLocalizedStrings(userDataState: userDataState, readingDayCount: readingDayCount)

        return WMFYearInReviewAnnouncementViewModel(
            animation: Self.animation,
            riveText: [
                CoverTextPath.title: localizedStrings.animationAccessibilityLabel,
                CoverTextPath.body: localizedStrings.body
            ],
            localizedStrings: localizedStrings,
            delegate: delegate
        )
    }

    func makeLocalizedStrings(userDataState: UserDataState, readingDayCount: Int) -> WMFYearInReviewAnnouncementViewModel.LocalizedStrings {
        let headline: String
        let body: String
        switch userDataState {
        case .dataRich:
            headline = WMFLocalizedString("year-in-review-2026-announcement-headline", value: "Your Wikipedia Year in Review is here", comment: "Headline of the Year in Review announcement for readers with enough reading data. It is drawn inside the artwork, so VoiceOver reads this text.")
            let format = WMFLocalizedString("year-in-review-2026-announcement-personalized-body", value: "Thanks for spending {{PLURAL:%1$d|%1$d day|%1$d days}} on your trusty Wikipedia App in 2026.", comment: "Body text of the Year in Review announcement for readers with enough reading data. %1$d is replaced with the number of days the reader read articles in the app.")
            body = String.localizedStringWithFormat(format, readingDayCount)
        case .lowData:
            headline = collectiveHeadline
            body = collectiveBody
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
            return (collectiveHeadline, collectiveBody)
        }
    }

    /// Used by the collective announcement and the collective log in prompt.
    private var collectiveHeadline: String {
        WMFLocalizedString("year-in-review-2026-announcement-collective-headline", value: "Our Year in Review is here", comment: "Headline of the Year in Review announcement for readers without enough reading data for a personalized Year in Review, and title of the log in prompt shown to them. On the announcement it is drawn inside the artwork, so VoiceOver reads this text.")
    }

    /// Used by the collective announcement and the collective log in prompt.
    private var collectiveBody: String {
        WMFLocalizedString("year-in-review-2026-announcement-collective-body", value: "There wasn't enough activity to generate your own Year in Review this time, but you can still explore what the world discovered together.", comment: "Body text of the Year in Review announcement for readers without enough reading data for a personalized Year in Review, and message of the log in prompt shown to them.")
    }
}
