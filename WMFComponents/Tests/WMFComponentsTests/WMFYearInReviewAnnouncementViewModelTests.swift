import Combine
import Testing
import UIKit
@testable import WMFComponents

@MainActor
private final class AnnouncementDelegateSpy: WMFYearInReviewAnnouncementDelegate {
    var taps: [String] = []

    func yearInReviewAnnouncementDidTapExplore() { taps.append("explore") }
    func yearInReviewAnnouncementDidTapClose() { taps.append("close") }
    func yearInReviewAnnouncementDidTapLearnMore() { taps.append("learnMore") }
    func yearInReviewAnnouncementDidTapAboutInsights() { taps.append("aboutInsights") }
    func yearInReviewAnnouncementDidTapShareFeedback() { taps.append("shareFeedback") }
}

@MainActor
@Suite
struct WMFYearInReviewAnnouncementViewModelTests {

    private let delegate = AnnouncementDelegateSpy()

    private func makeViewModel(contentStyle: WMFYearInReviewSlideViewModel.ContentStyle = .light) -> WMFYearInReviewAnnouncementViewModel {
        WMFYearInReviewAnnouncementViewModel(
            animation: WMFRiveAnimation(resourceName: "all_templates", artboardName: "cover", stateMachineName: "cover-statemachine"),
            localizedStrings: .init(
                animationAccessibilityLabel: "Title",
                body: "Body",
                exploreButtonTitle: "Explore",
                wIconAccessibilityLabel: "Wikipedia",
                closeButtonAccessibilityLabel: "Close",
                moreButtonAccessibilityLabel: "More",
                learnMoreButtonTitle: "Learn more",
                aboutInsightsButtonTitle: "About your insights",
                shareFeedbackButtonTitle: "Share feedback"
            ),
            contentStyle: contentStyle,
            lightContentFlag: WMFRiveBool(path: "isUIWhite"),
            delegate: delegate
        )
    }

    // MARK: - Content style

    /// The style passed in shows until the artwork loads, so the controls are not blank before then.
    @Test
    func thePassedStyleShowsBeforeTheArtworkLoads() {
        let viewModel = makeViewModel(contentStyle: .light)

        #expect(viewModel.contentStyle == .light)
        #expect(viewModel.contentColor == WMFYearInReviewSlideViewModel.ContentStyle.light.color)
    }

    /// The flag in the .riv replaces the passed style, the same as on the slides.
    @Test
    func theLightContentFlagSetsTheStyle() {
        let viewModel = makeViewModel(contentStyle: .light)

        viewModel.didReadLightContentFlag(false)
        #expect(viewModel.contentStyle == .dark)
        #expect(viewModel.contentColor == WMFYearInReviewSlideViewModel.ContentStyle.dark.color)

        viewModel.didReadLightContentFlag(true)
        #expect(viewModel.contentStyle == .light)
        #expect(viewModel.contentColor == WMFYearInReviewSlideViewModel.ContentStyle.light.color)
    }

    /// The hosting controller colors the navigation bar from this publisher, with the value it sends.
    @Test
    func theContentStylePublisherSendsTheNewStyle() {
        let viewModel = makeViewModel(contentStyle: .light)
        var received: [WMFYearInReviewSlideViewModel.ContentStyle] = []
        let cancellable = viewModel.$contentStyle.dropFirst().sink { received.append($0) }

        viewModel.didReadLightContentFlag(false)

        #expect(received == [.dark])
        cancellable.cancel()
    }

    // MARK: - Actions

    @Test
    func eachActionCallsTheDelegate() {
        let viewModel = makeViewModel()

        viewModel.tappedExplore()
        viewModel.tappedClose()
        viewModel.tappedLearnMore()
        viewModel.tappedAboutInsights()
        viewModel.tappedShareFeedback()

        #expect(delegate.taps == ["explore", "close", "learnMore", "aboutInsights", "shareFeedback"])
    }
}
