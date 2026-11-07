import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

@MainActor
@Suite(.serialized)
final class WMFActivityTabViewModelTests {

    private let fixture = WMFDataTestFixture()

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    private var project: WMFProject {
        .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }

    private func makeViewModel(_ authenticationState: LoginState) -> WMFActivityTabViewModel {
        WMFActivityTabViewModel(
            localizedStrings: .testStrings,
            dataController: WMFActivityTabDataController(),
            authenticationState: authenticationState
        )
    }

    private func item(_ title: String, _ itemType: TimelineItemType) -> TimelineItem {
        TimelineItem(id: title, date: Date(), titleHtml: title, projectID: project.id, pageTitle: title, url: nil, namespaceID: 0, itemType: itemType)
    }

    private func section(_ itemTypes: [TimelineItemType], daysAgo: Int = 0) throws -> TimelineViewModel.TimelineSection {
        let date = try #require(Calendar.current.date(byAdding: .day, value: -daysAgo, to: Date()))
        return TimelineViewModel.TimelineSection(date: date, items: itemTypes.enumerated().map { item("\(daysAgo)-\($0.offset)", $0.element) })
    }

    private func coreDataStore() throws -> WMFCoreDataStore {
        let store: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore
        return try #require(store)
    }

    private func addRead(_ title: String, at date: Date) async throws {
        let store = try coreDataStore()
        let pageViewsDataController = try WMFPageViewsDataController(coreDataStore: store)
        _ = try await pageViewsDataController.addPageView(title: title, namespaceID: 0, project: project, previousPageViewObjectID: nil, timestamp: date)
    }

    private func fetchDataAndWait(_ viewModel: WMFActivityTabViewModel, fromAppearance: Bool = false) async -> Bool {
        await withCheckedContinuation { continuation in
            viewModel.fetchDataCompleteAction = { continuation.resume(returning: $0) }
            viewModel.fetchData(fromAppearance: fromAppearance)
        }
    }

    // MARK: - Empty state

    @Test
    func aLoggedInUserSeesTheEmptyStateOnlyForOneEmptySection() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)

            viewModel.sections = []
            #expect(!viewModel.shouldShowEmptyState)

            viewModel.sections = [try section([])]
            #expect(viewModel.shouldShowEmptyState)

            viewModel.sections = [try section([.saved])]
            #expect(!viewModel.shouldShowEmptyState)

            viewModel.sections = [try section([]), try section([], daysAgo: 1)]
            #expect(!viewModel.shouldShowEmptyState)
        }
    }

    @Test
    func aLoggedOutOrTemporaryUserSeesTheEmptyStateWithoutAReadItem() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            for authenticationState in [LoginState.loggedOut, .temp] {
                let viewModel = makeViewModel(authenticationState)

                viewModel.sections = []
                #expect(viewModel.shouldShowEmptyState)

                viewModel.sections = [try section([.saved, .edit])]
                #expect(viewModel.shouldShowEmptyState)

                viewModel.sections = [try section([.saved]), try section([.read], daysAgo: 1)]
                #expect(!viewModel.shouldShowEmptyState)
            }
        }
    }

    // MARK: - Your impact

    @Test
    func yourImpactHeaderDependsOnAPositiveGlobalEditCount() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)
            #expect(!viewModel.shouldShowYourImpactHeader)

            viewModel.globalEditCount = 0
            #expect(!viewModel.shouldShowYourImpactHeader)

            viewModel.globalEditCount = 1
            #expect(viewModel.shouldShowYourImpactHeader)
        }
    }

    // MARK: - Username and strings

    @Test
    func updateUsernameFormatsTheReadingTitle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)

            viewModel.updateUsername(username: "Ada")
            #expect(viewModel.articlesReadViewModel.username == "Ada")
            #expect(viewModel.articlesReadViewModel.usernamesReading == "Ada is reading")

            viewModel.updateUsername(username: "")
            #expect(viewModel.articlesReadViewModel.usernamesReading == "Someone is reading")

            viewModel.updateUsername(username: nil)
            #expect(viewModel.articlesReadViewModel.username == "")
            #expect(viewModel.articlesReadViewModel.usernamesReading == "Someone is reading")
        }
    }

    @Test
    func hoursMinutesReadUsesTheReadingTotals() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)
            viewModel.articlesReadViewModel.hoursRead = 2
            viewModel.articlesReadViewModel.minutesRead = 35

            #expect(viewModel.hoursMinutesRead == "2h 35m")
        }
    }

    @Test
    func navigationCallbacksAreForwarded() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)
            var contributionsPushes = 0
            var toasts = 0
            viewModel.pushToContributions = { contributionsPushes += 1 }
            viewModel.presentCustomizeLogInToastAction = { toasts += 1 }

            viewModel.navigateToContributions()
            viewModel.customizeViewModel.presentLoggedInToastAction?()

            #expect(contributionsPushes == 1)
            #expect(toasts == 1)
        }
    }

    // MARK: - Authentication changes

    @Test
    func emptyViewFollowsTheAuthenticationState() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            #expect(makeViewModel(.loggedIn).emptyViewModel.localizedStrings.title == "Empty, logged in")
            #expect(makeViewModel(.loggedOut).emptyViewModel.localizedStrings.title == "Empty, logged out")
            #expect(makeViewModel(.temp).emptyViewModel.localizedStrings.title == "Empty, logged out")
        }
    }

    @Test
    func stayingLoggedInWithoutARefetchStopsLoadingAtOnce() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedOut)
            viewModel.globalEditCount = 4

            viewModel.updateAuthenticationState(authState: .loggedIn, needsRefetch: false)

            #expect(!viewModel.isLoading)
            #expect(viewModel.authenticationState == .loggedIn)
            #expect(viewModel.customizeViewModel.isLoggedIn)
            #expect(viewModel.emptyViewModel.localizedStrings.title == "Empty, logged in")
            #expect(viewModel.globalEditCount == 4)
        }
    }

    @Test
    func loggingOutClearsTheAccountDataAndReloadsTheTimeline() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedIn)
            viewModel.updateUsername(username: "Ada")
            viewModel.globalEditCount = 4
            viewModel.sections = [try section([.read])]

            viewModel.updateAuthenticationState(authState: .loggedOut, needsRefetch: false)

            #expect(viewModel.isLoading)
            #expect(viewModel.authenticationState == .loggedOut)
            #expect(!viewModel.customizeViewModel.isLoggedIn)
            #expect(viewModel.articlesReadViewModel.usernamesReading == "Someone is reading")
            #expect(viewModel.globalEditCount == nil)

            try await waitForActivityTabCondition { !viewModel.isLoading }

            #expect(viewModel.sections.map(\.items.count) == [0])
            #expect(viewModel.shouldShowEmptyState)
        }
    }

    @Test
    func aRefetchWhileLoggedInClearsThenReloadsTheTimeline() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedOut)
            viewModel.globalEditCount = 4

            viewModel.updateAuthenticationState(authState: .loggedIn, needsRefetch: true)
            #expect(viewModel.isLoading)

            try await waitForActivityTabCondition { !viewModel.isLoading }

            #expect(viewModel.globalEditCount == nil)
            #expect(viewModel.sections.map(\.items.count) == [0])
            #expect(viewModel.shouldShowEmptyState)
        }
    }

    // MARK: - Fetching

    @Test
    func fetchDataReportsCompletionAndStopsLoading() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedOut)

            let fromAppearance = await fetchDataAndWait(viewModel, fromAppearance: true)

            #expect(fromAppearance)
            #expect(!viewModel.isLoading)
        }
    }

    @Test
    func aUserWithNothingToShowGetsTheExploreCallToAction() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedOut)

            _ = await fetchDataAndWait(viewModel)

            #expect(viewModel.shouldShowExploreCTA)
            #expect(viewModel.isEmpty)
        }
    }

    @Test
    func theExploreCallToActionNeedsTheExploreFeed() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = makeViewModel(.loggedOut)
            viewModel.isExploreFeedOn = false

            _ = await fetchDataAndWait(viewModel)

            #expect(!viewModel.shouldShowExploreCTA)
        }
    }

    @Test
    func aReaderDoesNotGetTheExploreCallToAction() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addRead("Cat", at: Date().addingTimeInterval(-3600))
            let viewModel = makeViewModel(.loggedOut)

            _ = await fetchDataAndWait(viewModel)

            #expect(viewModel.articlesReadViewModel.totalArticlesRead == 1)
            #expect(!viewModel.shouldShowExploreCTA)
            #expect(!viewModel.isEmpty)
        }
    }
}
