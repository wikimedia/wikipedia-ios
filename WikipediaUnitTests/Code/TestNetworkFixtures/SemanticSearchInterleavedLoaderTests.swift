import Foundation
import Testing
import WMFData
@testable import Wikipedia
@testable import WMF

/// The fallbacks of US-4: search keeps working when the semantic request is slow or fails. The forced
/// scenarios of developer settings stand in for the semantic request, so no test sends it. The lexical
/// request gets its data from the fixture service.
struct SemanticSearchInterleavedLoaderTests {

    private let siteURL = URL(string: "https://fr.wikipedia.org")!
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "fr", languageVariantCode: nil))

    @Test(arguments: [
        (WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario.semanticTimesOut, WMFSemanticSearchInterleaveState.lexicalOnlyTimeout),
        (.semanticFails, .lexicalOnlyError),
        (.semanticRateLimited, .lexicalOnlyRateLimited),
        (.semanticReturnsNothing, .lexicalOnlyEmpty)
    ])
    func aSemanticFallbackShowsTheLexicalList(scenario: WMFSemanticSearchInterleavedDataController.ForcedRetrievalScenario, expectedState: WMFSemanticSearchInterleaveState) async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = try fixtureData(named: "ArticleSearchPrefixMany")

        let outcome = try await harness.loader.fetchResults(for: "foo", siteURL: siteURL, project: project, forcedScenario: scenario)

        #expect(outcome.state == expectedState)
        #expect(outcome.items.count == WMFSemanticSearchInterleavedConfiguration.listLength)
        #expect(outcome.items.allSatisfy { $0.source == .lexicalPrefix })
        #expect(outcome.items.allSatisfy { outcome.lexicalResultsByPageID[$0.pageID] != nil })
        #expect(outcome.semanticResultsByPageID.isEmpty)
    }

    /// The lexical request fails and the semantic request fails. There is no list: the existing error state shows.
    @Test
    func aLexicalFailureAndASemanticFailureAreAnError() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = Data("not json".utf8)

        await #expect(performing: {
            try await harness.loader.fetchResults(for: "foo", siteURL: siteURL, project: project, forcedScenario: .semanticFails)
        }, throws: { error in
            guard case SearchResultsLoader.Failure.fetch(_, let type) = error else { return false }
            return type == .prefix
        })
    }

    @Test
    func theForcedFailureOfBothRequestsIsAnErrorWithNoLexicalRequest() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }

        await #expect(throws: SearchResultsLoader.Failure.self) {
            try await harness.loader.fetchResults(for: "foo", siteURL: siteURL, project: project, forcedScenario: .bothFail)
        }
        #expect(harness.service.capturedRequests.isEmpty)
    }

    @Test
    func bothReturningNothingIsAnEmptyListWithNoLexicalRequest() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }

        let outcome = try await harness.loader.fetchResults(for: "foo", siteURL: siteURL, project: project, forcedScenario: .bothReturnNothing)

        #expect(outcome.state == WMFSemanticSearchInterleaveState.none)
        #expect(outcome.items.isEmpty)
        #expect(harness.service.capturedRequests.isEmpty)
    }

    /// The lexical request fails and the semantic request answers with no results. The list is empty, so the
    /// reader sees the empty state and not the error state.
    @Test
    func aLexicalFailureWithAnEmptySemanticAnswerIsAnEmptyList() async throws {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }
        harness.service.responseData = Data("not json".utf8)

        let outcome = try await harness.loader.fetchResults(for: "foo", siteURL: siteURL, project: project, forcedScenario: .semanticReturnsNothing)

        #expect(outcome.state == WMFSemanticSearchInterleaveState.none)
        #expect(outcome.items.isEmpty)
    }

    @Test
    func aCancelledSearchThrowsACancellationError() async {
        let harness = makeHarness()
        defer { harness.fetcher.cancelAllFetches() }

        let task = Task {
            withUnsafeCurrentTask { $0?.cancel() }
            return try await harness.loader.fetchResults(for: "foo", siteURL: siteURL, project: project, forcedScenario: .semanticFails)
        }

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    // MARK: - Helpers

    private func makeHarness() -> (loader: SemanticSearchInterleavedLoader, fetcher: WMFSearchFetcher, service: SearchFixtureService) {
        let service = SearchFixtureService()
        let fetcher = WMFSearchFetcher(dataController: WMFArticleSearchDataController(basicService: service))
        let loader = SemanticSearchInterleavedLoader(lexicalLoader: SearchResultsLoader(fetcher: fetcher))
        return (loader, fetcher, service)
    }

    private func fixtureData(named name: String) throws -> Data {
        try #require(Bundle(for: SemanticSearchInterleavedLoaderTestBundleToken.self).wmf_data(fromContentsOfFile: name, ofType: "json"))
    }
}

private final class SemanticSearchInterleavedLoaderTestBundleToken {}
