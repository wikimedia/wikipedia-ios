import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

/// Reproduces the onboarding → settings round trip: an article selected on one instance of the
/// interests screen should reappear (selected) when the screen is opened again.
@Suite(.serialized)
@MainActor
final class WMFInterestsPersistenceRoundTripTests {

    private let fixture = WMFDataTestFixture()
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
    }

    private func waitFor(timeout: TimeInterval = 10, _ condition: @escaping () async -> Bool) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        var isMet = await condition()
        while !isMet && Date() < deadline {
            try await Task.sleep(nanoseconds: 50_000_000)
            isMet = await condition()
        }
        #expect(isMet, "Condition not met within \(timeout)s")
    }

    @Test
    func selectedArticlePersistsToNewInstance() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.coreDataStore)
            let pageInterest = try WMFPageInterestDataController(coreDataStore: store)
            let home = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())

            // First instance (onboarding): select an article
            let vm1 = WMFHomeFeedInterestsSettingsViewModel(dataController: home, pageInterestDataController: pageInterest, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
            let card = WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 1, title: "Candace_Oviatt", displayTitle: "Candace Oviatt", variantTitles: nil, description: nil, extract: nil, thumbnail: nil), project: project)
            vm1.gridViewModels = [card]
            vm1.toggleArticleSelection(card)
            #expect(card.isSelected)

            // Give the save Task time to persist
            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return !interests.isEmpty
            }

            // Second instance (settings): should load the saved article, selected
            let pageInterest2 = try WMFPageInterestDataController(coreDataStore: store)
            let home2 = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
            let vm2 = WMFHomeFeedInterestsSettingsViewModel(dataController: home2, pageInterestDataController: pageInterest2, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})

            try await waitFor {
                vm2.gridViewModels.contains { $0.isSelected }
            }

            let selected = vm2.gridViewModels.filter { $0.isSelected }
            #expect(selected.count == 1, "Expected the saved article to load as selected")
        }
    }

    /// Mirrors the onboarding launch race: the view model is created without a page interest
    /// controller (Core Data store not ready yet), then resolves it lazily once the store exists.
    @Test
    func selectionPersistsWhenControllerResolvedLazily() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.coreDataStore)
            let home = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())

            // nil controller injected; env store is set, so lazy resolution should succeed on use
            let vm = WMFHomeFeedInterestsSettingsViewModel(dataController: home, pageInterestDataController: nil, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
            let card = WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 2, title: "Marie_Curie", displayTitle: "Marie Curie", variantTitles: nil, description: nil, extract: nil, thumbnail: nil), project: project)
            vm.gridViewModels = [card]
            vm.toggleArticleSelection(card)

            let pageInterest = try WMFPageInterestDataController(coreDataStore: store)
            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return interests.contains { $0.title == "Marie_Curie" }
            }
        }
    }

    @Test
    func deselectingAnArticleRemovesThePersistedInterest() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.coreDataStore)
            let pageInterest = try WMFPageInterestDataController(coreDataStore: store)
            let home = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
            let vm = WMFHomeFeedInterestsSettingsViewModel(dataController: home, pageInterestDataController: pageInterest, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
            let card = WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 3, title: "Ada_Lovelace", displayTitle: "Ada Lovelace", variantTitles: nil, description: nil, extract: nil, thumbnail: nil), project: project)
            try await Task.sleep(nanoseconds: 300_000_000)
            vm.gridViewModels = [card]

            vm.toggleArticleSelection(card)
            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return !interests.isEmpty
            }

            vm.toggleArticleSelection(card)
            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return interests.isEmpty
            }
        }
    }

    @Test
    func deselectAllRemovesEveryPersistedInterest() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.coreDataStore)
            let pageInterest = try WMFPageInterestDataController(coreDataStore: store)
            let home = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())
            let vm = WMFHomeFeedInterestsSettingsViewModel(dataController: home, pageInterestDataController: pageInterest, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
            let cards = [
                WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 4, title: "Alan_Turing", displayTitle: "Alan Turing", variantTitles: nil, description: nil, extract: nil, thumbnail: nil), project: project),
                WMFInterestArticleCardViewModel(article: WMFRandomArticle(pageid: 5, title: "Grace_Hopper", displayTitle: "Grace Hopper", variantTitles: nil, description: nil, extract: nil, thumbnail: nil), project: project)
            ]
            // Let the init-time load of saved interests settle so it can't replace the injected grid.
            try await Task.sleep(nanoseconds: 300_000_000)
            vm.gridViewModels = cards
            cards.forEach { vm.toggleArticleSelection($0) }
            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return interests.count == 2
            }

            vm.deselectAll()
            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return interests.isEmpty
            }
        }
    }

    /// The wiki italicizes some article titles, so the search result's display title arrives as
    /// markup. Persisting that instead of the canonical title left the interest unresolvable —
    /// its summary and related-pages lookups 404, so its card showed no image or description.
    @Test
    func searchResultWithAMarkedUpDisplayTitlePersistsTheCanonicalTitle() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let store = try #require(WMFDataEnvironment.current.coreDataStore)
            let pageInterest = try WMFPageInterestDataController(coreDataStore: store)
            let home = WMFHomeDataController(userDefaultsStore: WMFMockKeyValueStore())

            let vm = WMFHomeFeedInterestsSettingsViewModel(dataController: home, pageInterestDataController: pageInterest, project: project, logDidTapTopic: {}, logDidTapArticle: {}, logDidTapDeselectAll: {})
            let result = WMFArticleSearchResult(pageID: 18586452, namespace: 0, title: "The Macomber Affair", displayTitle: "<i>The Macomber Affair</i>", description: "1947 film by Zoltan Korda", index: 1, thumbnail: nil)
            #expect(vm.addSearchResult(result))

            try await waitFor {
                let interests = (try? await pageInterest.fetchPageInterests(project: self.project)) ?? []
                return !interests.isEmpty
            }

            let interests = try await pageInterest.fetchPageInterests(project: project)
            #expect(interests.map { $0.title } == ["The_Macomber_Affair"])
        }
    }
}
