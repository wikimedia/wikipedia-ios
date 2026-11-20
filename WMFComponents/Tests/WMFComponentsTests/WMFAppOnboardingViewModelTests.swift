import Testing
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite
struct WMFAppOnboardingViewModelTests {

    private final class CompletionBox {
        var completed = false
    }

    private final class LogBox {
        var impressions: [WMFAppOnboardingViewModel.Step] = []
        var nexts: [WMFAppOnboardingViewModel.Step] = []
        var feedPreferenceImpressions = 0
    }

    private func makeViewModel(languages: [WMFAppOnboardingViewModel.LanguageItem] = [],
                               completionBox: CompletionBox = CompletionBox(),
                               logBox: LogBox = LogBox()) -> WMFAppOnboardingViewModel {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        // Fully injected so no test in this suite performs real network I/O (the loading-step
        // test in particular races a feed fetch against a timeout and flaked on CI when the
        // fetch was real).
        let dataController = WMFHomeDataController(
            feedDataController: WMFMockFeedDataController(response: WMFFeedAPIResponse(todaysFeaturedArticle: nil, mostRead: nil, image: nil, news: nil)),
            basicService: WMFMockBasicService(),
            userDefaultsStore: WMFMockKeyValueStore(),
            onThisDayDataController: WMFOnThisDayDataController(basicService: WMFMockBasicService())
        )
        let interestsViewModel = WMFHomeFeedInterestsSettingsViewModel(dataController: dataController, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
        let feedPreferenceViewModel = WMFAppOnboardingFeedPreferenceViewModel(dataController: dataController, project: project, logImpression: { _ in logBox.feedPreferenceImpressions += 1 }, logDidTapCommunity: {}, logDidTapPersonalized: {})
        return WMFAppOnboardingViewModel(
            languages: languages,
            interestsViewModel: interestsViewModel,
            feedPreferenceViewModel: feedPreferenceViewModel,
            didTapLearnMoreAboutWikipedia: {},
            didTapPrivacyPolicy: {},
            didTapTermsOfUse: {},
            didTapAddLanguages: {},
            onCompletion: { completionBox.completed = true },
            logImpression: { logBox.impressions.append($0) },
            logSkip: { _ in },
            logNext: { logBox.nexts.append($0) }
        )
    }

    private func advanceToPersonalizationIntro(_ viewModel: WMFAppOnboardingViewModel) {
        while viewModel.currentStep != .personalizationIntro {
            viewModel.advance()
        }
    }

    @Test
    func stepsAreInExpectedOrder() {
        let viewModel = makeViewModel()
        #expect(viewModel.steps == [.intro, .dataPrivacy, .languages, .personalizationIntro, .interests, .feedPreference, .loading])
        #expect(viewModel.currentStep == .intro)
    }

    @Test
    func advanceMovesThroughAllSteps() {
        let viewModel = makeViewModel()
        viewModel.advance()
        #expect(viewModel.currentStep == .dataPrivacy)
        viewModel.advance()
        #expect(viewModel.currentStep == .languages)
        viewModel.advance()
        #expect(viewModel.currentStep == .personalizationIntro)
        viewModel.advance()
        #expect(viewModel.currentStep == .interests)
        viewModel.advance()
        #expect(viewModel.currentStep == .feedPreference)
        viewModel.advance()
        #expect(viewModel.currentStep == .loading)
    }

    @Test
    func advanceOnLastStepCallsCompletion() {
        let box = CompletionBox()
        let viewModel = makeViewModel(completionBox: box)
        for _ in 0..<(viewModel.steps.count - 1) {
            viewModel.advance()
        }
        #expect(box.completed == false)
        viewModel.advance()
        #expect(box.completed == true)
    }

    @Test
    func skipResetsFeedPreferenceToDefault() {
        let viewModel = makeViewModel()
        viewModel.feedPreferenceViewModel.isPersonalizedLoading = false // as after the load
        viewModel.feedPreferenceViewModel.select(.personalized)
        viewModel.skip()
        #expect(viewModel.feedPreferenceViewModel.selection == .community)
    }

    @Test
    func skipCallsCompletionImmediately() {
        let box = CompletionBox()
        let viewModel = makeViewModel(completionBox: box)
        viewModel.advance() // dataPrivacy
        viewModel.skip()
        #expect(box.completed == true)
    }

    @Test
    func loadingStepCompletesAfterFeedLoadAndMinimumDisplay() async throws {
        let box = CompletionBox()
        let viewModel = makeViewModel(completionBox: box)
        viewModel.completeAfterLoadingFeed(minimumDisplay: 0, maximumWait: 0)

        // Poll rather than a fixed sleep: completion hops through several tasks, which can
        // exceed a short fixed wait on slow CI runners.
        let deadline = ContinuousClock.now.advanced(by: .seconds(10))
        while !box.completed && ContinuousClock.now < deadline {
            try await Task.sleep(for: .milliseconds(50))
        }
        #expect(box.completed == true)
    }

    @Test
    func skipAndDotsOnlyShowOnPersonalizationSteps() {
        let viewModel = makeViewModel()
        #expect(viewModel.showsSkipAndDots == false) // intro
        viewModel.advance()
        #expect(viewModel.showsSkipAndDots == false) // dataPrivacy
        viewModel.advance()
        #expect(viewModel.showsSkipAndDots == false) // languages
        viewModel.advance()
        #expect(viewModel.showsSkipAndDots == true) // personalizationIntro
        viewModel.advance()
        #expect(viewModel.showsSkipAndDots == true) // interests
        viewModel.advance()
        #expect(viewModel.showsSkipAndDots == true) // feedPreference
        viewModel.advance()
        #expect(viewModel.showsSkipAndDots == false) // loading
    }

    @Test
    func toolbarHiddenOnlyOnLoadingStep() {
        let viewModel = makeViewModel()
        for _ in 0..<(viewModel.steps.count - 1) {
            #expect(viewModel.showsToolbar == true)
            viewModel.advance()
        }
        #expect(viewModel.currentStep == .loading)
        #expect(viewModel.showsToolbar == false)
    }

    @Test
    func dotIndexTracksPersonalizationSteps() {
        let viewModel = makeViewModel()
        #expect(viewModel.currentDotIndex == nil) // intro
        #expect(viewModel.personalizationSteps.count == 3)

        viewModel.advance() // dataPrivacy
        viewModel.advance() // languages
        viewModel.advance() // personalizationIntro
        #expect(viewModel.currentDotIndex == 0)
        viewModel.advance() // interests
        #expect(viewModel.currentDotIndex == 1)
        viewModel.advance() // feedPreference
        #expect(viewModel.currentDotIndex == 2)
    }

    @Test
    func updateLanguagesReplacesList() {
        let initial = [WMFAppOnboardingViewModel.LanguageItem(id: "en", displayName: "English", isPrimary: true)]
        let viewModel = makeViewModel(languages: initial)
        #expect(viewModel.languages.count == 1)

        viewModel.updateLanguages([
            WMFAppOnboardingViewModel.LanguageItem(id: "en", displayName: "English", isPrimary: true),
            WMFAppOnboardingViewModel.LanguageItem(id: "zh", displayName: "中文", isPrimary: false)
        ])
        #expect(viewModel.languages.count == 2)
        #expect(viewModel.languages.last?.isPrimary == false)
    }

    // MARK: - Swiping (T434325)

    @Test
    func swipeMovesBackAndForthBetweenPersonalizationSteps() {
        let viewModel = makeViewModel()
        advanceToPersonalizationIntro(viewModel)

        viewModel.swipe(to: .interests)
        #expect(viewModel.currentStep == .interests)
        viewModel.swipe(to: .feedPreference)
        #expect(viewModel.currentStep == .feedPreference)
        viewModel.swipe(to: .interests)
        #expect(viewModel.currentStep == .interests)
        viewModel.swipe(to: .personalizationIntro)
        #expect(viewModel.currentStep == .personalizationIntro)
    }

    @Test
    func swipeLogsImpressionsButNoNextClick() {
        let logBox = LogBox()
        let viewModel = makeViewModel(logBox: logBox)
        advanceToPersonalizationIntro(viewModel)
        let nextCount = logBox.nexts.count
        logBox.impressions.removeAll()

        viewModel.swipe(to: .interests)
        viewModel.swipe(to: .personalizationIntro)
        viewModel.swipe(to: .interests)

        #expect(logBox.impressions == [.interests, .personalizationIntro, .interests])
        #expect(logBox.nexts.count == nextCount)
    }

    @Test
    func swipeCannotLeaveThePersonalizationSteps() {
        let viewModel = makeViewModel()
        advanceToPersonalizationIntro(viewModel)
        viewModel.swipe(to: .languages)
        #expect(viewModel.currentStep == .personalizationIntro)

        viewModel.swipe(to: .interests)
        viewModel.swipe(to: .feedPreference)
        viewModel.swipe(to: .loading)
        #expect(viewModel.currentStep == .feedPreference)
    }

    @Test
    func swipeIsIgnoredBeforeThePersonalizationSteps() {
        let viewModel = makeViewModel()
        viewModel.swipe(to: .interests)
        #expect(viewModel.currentStep == .intro)
    }

    @Test
    func condensedFlowCannotSwipeBackToPersonalizationIntro() {
        let viewModel = makeViewModel()
        viewModel.jumpToStep(.interests)
        #expect(viewModel.swipeableSteps == [.interests, .feedPreference])

        viewModel.swipe(to: .personalizationIntro)
        #expect(viewModel.currentStep == .interests)
    }

    @Test
    func advanceInsideThePagerLogsTheImpressionOfTheNewStep() {
        let logBox = LogBox()
        let viewModel = makeViewModel(logBox: logBox)
        viewModel.advance() // dataPrivacy
        viewModel.advance() // languages
        viewModel.advance() // personalizationIntro: the pager logs it when it appears
        #expect(logBox.impressions.isEmpty)

        viewModel.advance() // interests
        viewModel.advance() // feedPreference
        #expect(logBox.impressions == [.interests, .feedPreference])

        viewModel.advance() // loading: logged by its own onAppear
        #expect(logBox.impressions == [.interests, .feedPreference])
    }

    @Test
    func swipingAwayFromFeedPreferenceDuringTheLoadLogsNoImpression() async {
        let logBox = LogBox()
        let viewModel = makeViewModel(logBox: logBox)
        advanceToPersonalizationIntro(viewModel)
        viewModel.advance() // interests
        viewModel.advance() // feedPreference: the load starts and the impression waits for it

        viewModel.swipe(to: .interests)
        await viewModel.feedPreferenceViewModel.waitForLoadTasks()
        #expect(logBox.feedPreferenceImpressions == 0, "The reader is on the interests step when the load finishes")

        viewModel.swipe(to: .feedPreference)
        #expect(logBox.feedPreferenceImpressions == 1)
    }
}
