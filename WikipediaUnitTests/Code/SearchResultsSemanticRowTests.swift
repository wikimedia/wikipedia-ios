import Foundation
import Testing
@testable import Wikipedia
@testable import WMF
import WMFComponents
import WMFData

/// A semantic row of the interleaved list opens the article at its passage. Every other row opens
/// the article at the top, as before.
@MainActor
@Suite(.serialized)
struct SearchResultsSemanticRowTests {

    private let siteURL = URL(string: "https://en.wikipedia.org")!
    private let project = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private struct SemanticOpening {
        let result: WMFSemanticSearchResult
        let project: WMFProject
        let needsNewTab: Bool
    }

    private struct ArticleOpening: Equatable {
        let articleURL: URL
        let needsNewTab: Bool
    }

    @MainActor
    private final class Recorder {
        var semanticOpenings: [SemanticOpening] = []
        var articleOpenings: [ArticleOpening] = []
    }

    @Test
    func aSemanticRowOpensWithItsPassage() async throws {
        let viewController = try await makeViewController()
        let semanticResult = makeSemanticResult(title: "Information", sectionTitle: "Definitions")
        let row = try #require(makeRow(title: "Information"))
        viewController.semanticResultsByArticleURL = [row.id: semanticResult]

        let recorder = Recorder()
        viewController.semanticResultTappedAction = { result, project, needsNewTab in
            recorder.semanticOpenings.append(SemanticOpening(result: result, project: project, needsNewTab: needsNewTab))
        }
        viewController.articleTappedAction = { articleURL, needsNewTab in
            recorder.articleOpenings.append(ArticleOpening(articleURL: articleURL, needsNewTab: needsNewTab))
        }

        viewController.openArticle(for: row, needsNewTab: false)
        viewController.openArticle(for: row, needsNewTab: true)

        #expect(recorder.semanticOpenings.map(\.result.pageID) == [semanticResult.pageID, semanticResult.pageID])
        #expect(recorder.semanticOpenings.map(\.project) == [project, project])
        #expect(recorder.semanticOpenings.map(\.needsNewTab) == [false, true])
        #expect(recorder.articleOpenings.isEmpty)
    }

    @Test
    func aLexicalRowOpensAtTheTop() async throws {
        let viewController = try await makeViewController()
        let lexicalRow = try #require(makeRow(title: "Cat"))
        viewController.semanticResultsByArticleURL = [try #require(makeRow(title: "Information")).id: makeSemanticResult(title: "Information", sectionTitle: "Definitions")]

        let recorder = Recorder()
        viewController.semanticResultTappedAction = { result, project, needsNewTab in
            recorder.semanticOpenings.append(SemanticOpening(result: result, project: project, needsNewTab: needsNewTab))
        }
        viewController.articleTappedAction = { articleURL, needsNewTab in
            recorder.articleOpenings.append(ArticleOpening(articleURL: articleURL, needsNewTab: needsNewTab))
        }

        viewController.openArticle(for: lexicalRow, needsNewTab: true)

        #expect(recorder.semanticOpenings.isEmpty)
        #expect(recorder.articleOpenings == [ArticleOpening(articleURL: lexicalRow.articleURL, needsNewTab: true)])
    }

    /// The link search of the editor sets no semantic action. A semantic row gives it the article URL.
    @Test
    func aSemanticRowOpensAtTheTopWithoutTheSemanticAction() async throws {
        let viewController = try await makeViewController()
        let row = try #require(makeRow(title: "Information"))
        viewController.semanticResultsByArticleURL = [row.id: makeSemanticResult(title: "Information", sectionTitle: "Definitions")]

        let recorder = Recorder()
        viewController.articleTappedAction = { articleURL, needsNewTab in
            recorder.articleOpenings.append(ArticleOpening(articleURL: articleURL, needsNewTab: needsNewTab))
        }

        viewController.openArticle(for: row, needsNewTab: false)

        #expect(recorder.articleOpenings == [ArticleOpening(articleURL: row.articleURL, needsNewTab: false)])
    }

    @Test
    func theArticleOpensAtTheSectionOfThePassage() throws {
        let result = makeSemanticResult(title: "Information theory", sectionTitle: "Historical background")

        let articleURL = try #require(SearchViewController.articleURL(for: result, project: project))

        #expect(articleURL.wmf_title == "Information theory")
        #expect(articleURL.fragment == "Historical_background")
    }

    @Test
    func aPassageInTheLeadOpensTheArticleAtTheTop() throws {
        let result = makeSemanticResult(title: "Information theory", sectionTitle: nil)

        let articleURL = try #require(SearchViewController.articleURL(for: result, project: project))

        #expect(articleURL.wmf_title == "Information theory")
        #expect(articleURL.fragment == nil)
    }

    // MARK: - Helpers

    private func makeViewController() async throws -> SearchResultsViewController {
        let dataStore = await withCheckedContinuation { continuation in
            MWKDataStore.createTemporaryDataStore { dataStore in
                continuation.resume(returning: dataStore)
            }
        }
        dataStore.removeFolderAtBasePath()
        return SearchResultsViewController(source: .searchTab, dataStore: dataStore)
    }

    private func makeRow(title: String) -> WMFSearchResultsViewModel.SearchResult? {
        guard let articleURL = siteURL.wmf_URL(withTitle: title) else { return nil }
        return WMFSearchResultsViewModel.SearchResult(articleURL: articleURL, pageTitle: title, title: title, titleHTML: title, description: nil, thumbnailURL: nil)
    }

    private func makeSemanticResult(title: String, sectionTitle: String?) -> WMFSemanticSearchResult {
        WMFSemanticSearchResult(pageID: 42, title: title, snippetHTML: "the <span class=\"searchmatch\">transmission</span> of information", sectionTitle: sectionTitle, redirectTitle: nil, thumbnailURL: nil)
    }
}
