import Foundation
import Testing
import WMFDataTestSupport
@testable import WMFComponents
@testable import WMFData
@testable import WMFDataMocks

/// Answers every request after a delay, as the network does. The saved articles module asks for
/// article summaries before it reports its count, so this makes that count arrive late.
private final class WMFActivityTabSlowService: WMFService {

    private let delay: TimeInterval = 1

    private var noResponse: Error {
        NSError(domain: "WMFActivityTabSlowService", code: 1)
    }

    private func respond(_ completion: @escaping @Sendable () -> Void) {
        DispatchQueue.global().asyncAfter(deadline: .now() + delay, execute: completion)
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<Data, Error>) -> Void) {
        let error = noResponse
        respond { completion(.failure(error)) }
    }

    func perform<R: WMFServiceRequest>(request: R, completion: @escaping @Sendable (Result<[String: Any]?, Error>) -> Void) {
        let error = noResponse
        respond { completion(.failure(error)) }
    }

    func performDecodableGET<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        let error = noResponse
        respond { completion(.failure(error)) }
    }

    func performDecodablePOST<R: WMFServiceRequest, T: Decodable & Sendable>(request: R, completion: @escaping @Sendable (Result<T, Error>) -> Void) {
        let error = noResponse
        respond { completion(.failure(error)) }
    }

    func clearCachedData() {}
}

/// `fetchData` does not wait for the saved count, so these tests make it arrive after `fetchData`
/// has finished. Code that handles the late count passes at any delay; a delay that is too short
/// could only let code that does not handle it pass wrongly, never fail correct code.
@MainActor
@Suite(.serialized)
final class WMFActivityTabSavedCountTests {

    private let fixture = WMFDataTestFixture()

    private var project: WMFProject {
        .wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
    }

    private func configureEnvironment() async throws {
        WMFDataEnvironment.current.userDefaultsStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.sharedCacheStore = WMFMockKeyValueStore()
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        WMFDataEnvironment.current.coreDataStore = try await fixture.makeTemporaryCoreDataStore()
        WMFDataEnvironment.current.basicService = WMFActivityTabSlowService()
    }

    private func coreDataStore() throws -> WMFCoreDataStore {
        let store: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore
        return try #require(store)
    }

    private func addSaved(_ title: String, at date: Date) async throws {
        let store = try coreDataStore()
        let context = try store.newBackgroundContext
        let projectID = project.id
        try await context.perform {
            let page = try store.create(entityType: CDPage.self, in: context)
            page.title = title
            page.namespaceID = 0
            page.projectID = projectID
            page.timestamp = date

            let savedInfo = try store.create(entityType: CDPageSavedInfo.self, in: context)
            savedInfo.savedDate = date
            savedInfo.page = page

            try store.saveIfNeeded(moc: context)
        }
    }

    private func makeViewModel() throws -> WMFActivityTabViewModel {
        WMFActivityTabViewModel(
            localizedStrings: .testStrings,
            dataController: WMFActivityTabDataController(),
            authenticationState: .loggedOut,
            savedArticlesDataController: WMFSavedArticlesDataController(coreDataStore: try coreDataStore())
        )
    }

    private func fetchDataAndWait(_ viewModel: WMFActivityTabViewModel) async {
        await withCheckedContinuation { continuation in
            viewModel.fetchDataCompleteAction = { _ in continuation.resume() }
            viewModel.fetchData()
        }
    }

    @Test
    func aSavedCountThatArrivesLateRemovesTheExploreCallToAction() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            try await addSaved("Cat", at: Date().addingTimeInterval(-3600))
            let viewModel = try makeViewModel()

            await fetchDataAndWait(viewModel)
            try await waitForActivityTabCondition { viewModel.articlesSavedViewModel.articlesSavedAmount == 1 }

            let showsExploreCallToAction = viewModel.shouldShowExploreCTA
            let isEmpty = viewModel.isEmpty
            #expect(showsExploreCallToAction == false)
            #expect(isEmpty == false)
        }
    }

    @Test
    func aUserWithNoSavedArticlesKeepsTheExploreCallToAction() async throws {
        try await fixture.withConfiguredEnvironment(configure: configureEnvironment) {
            let viewModel = try makeViewModel()

            await fetchDataAndWait(viewModel)

            let showsExploreCallToAction = viewModel.shouldShowExploreCTA
            let isEmpty = viewModel.isEmpty
            #expect(showsExploreCallToAction == true)
            #expect(isEmpty == true)
        }
    }
}
