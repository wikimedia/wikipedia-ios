import XCTest
@testable import WMFComponents
@testable import WMFData
import WMFDataMocks

@MainActor
final class WMFSavedAllArticlesViewModelTests: XCTestCase {

    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func article(_ title: String, lists: [String]) -> WMFSavedArticle {
        WMFSavedArticle(id: "\(project.id)|\(title)", title: title, project: project, savedDate: Date(timeIntervalSince1970: 1_000_000), readingListNames: lists)
    }

    private func makeViewModel(delegate: MockDelegate) -> WMFSavedAllArticlesViewModel {
        let strings = WMFSavedAllArticlesViewModel.LocalizedStrings(emptyStateTitle: "", emptyStateMessage: "", addToList: "", unsave: "", open: "", openInNewTab: "", openInBackgroundTab: "", removeFromSaved: "", share: "", listLimitExceeded: "", entryLimitExceeded: "", notSynced: "", articleQueuedToBeDownloaded: "")
        let dataController = WMFLegacyReadingListsDataController(delegate: delegate, userDefaultsStore: WMFMockKeyValueStore())
        return WMFSavedAllArticlesViewModel(dataController: dataController, localizedStrings: strings)
    }

    private func load(_ viewModel: WMFSavedAllArticlesViewModel, from delegate: MockDelegate) async {
        viewModel.loadArticles()
        for _ in 0..<50 where viewModel.articles != delegate.savedArticles {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    func testTagTapSendsTheArticleAsItIsNowNotAsTheRowWasBuilt() async {
        let delegate = MockDelegate()
        delegate.savedArticles = [article("Dog", lists: ["animals"])]
        let viewModel = makeViewModel(delegate: delegate)
        var tappedNames: [String] = []
        viewModel.didTapReadingListTag = { savedArticle, _ in
            tappedNames = savedArticle.readingListNames
        }

        await load(viewModel, from: delegate)
        let row = viewModel.rowViewModel(for: viewModel.articles[0])

        delegate.savedArticles = [article("Dog", lists: ["animals", "Zoology", "Égypte"])]
        await load(viewModel, from: delegate)
        XCTAssertTrue(viewModel.rowViewModel(for: viewModel.articles[0]) === row, "the row is reused across reloads")

        row.didTapReadingListTag?(nil)
        XCTAssertEqual(tappedNames, ["animals", "Zoology", "Égypte"])
    }
}

private final class MockDelegate: WMFLegacyReadingListsDataControllerDelegate {
    var savedArticles: [WMFSavedArticle] = []

    func fetchSavedArticles() async throws -> [WMFSavedArticle] { savedArticles }
    func fetchReadingLists() async throws -> [WMFReadingList] { [] }
    func fetchArticles(inReadingList readingListID: String) async throws -> [WMFSavedArticle] { [] }
    func defaultReadingListID() async throws -> String? { nil }
    func isDefaultReadingListEnabled() async -> Bool { false }
    func sortOrder(forReadingList readingListID: String) async throws -> WMFReadingListSortOrder? { nil }
    func setSortOrder(_ sortOrder: WMFReadingListSortOrder, forReadingList readingListID: String) async throws {}
    func createReadingList(name: String, description: String?) async throws -> WMFReadingList {
        WMFReadingList(id: name, name: name, description: description, isDefault: false, createdDate: Date(), articleCount: 0, articleIDs: [])
    }
    func updateReadingList(id readingListID: String, name: String?, description: String?) async throws {}
    func deleteReadingLists(ids readingListIDs: [String]) async throws {}
    func addArticles(ids articleIDs: [String], toReadingList readingListID: String) async throws {}
    func removeArticles(ids articleIDs: [String], fromReadingList readingListID: String) async throws {}
    func unsaveArticles(ids articleIDs: [String]) async throws {}
    func deleteSavedArticles(articles: [WMFSavedArticle], fromLongPress: Bool, completion: @escaping (Bool) -> Void) { completion(true) }
}
