import XCTest
import WMFData
import WMFDataMocks
import WMFDataTestSupport
@testable import WMFComponents

@MainActor
final class WMFAsyncPageRowSavedViewModelTests: XCTestCase {

    private let fixture = WMFDataTestFixture()
    private let localizedStrings = WMFAsyncPageRowSavedViewModel.LocalizedStrings(
        open: "Open",
        openInNewTab: "Open in new tab",
        openInBackgroundTab: "Open in background tab",
        removeFromSaved: "Remove from saved",
        share: "Share",
        listLimitExceeded: "List limit exceeded",
        entryLimitExceeded: "Entry limit exceeded",
        notSynced: "Not synced",
        articleQueuedToBeDownloaded: "Queued")

    override func setUp() async throws {
        try await super.setUp()
        await fixture.setUp()
        // The mock summary's display title is <span class="mw-page-title-main">Novela (právo)</span>
        WMFDataEnvironment.current.basicService = WMFMockBasicService(jsonResourceName: "article-summary-get")
        await fixture.resetWMFDataTestState()
    }

    override func tearDown() async throws {
        await fixture.tearDown()
        try await super.tearDown()
    }

    /// Creates a row and waits until it has loaded the summary. Each row uses a unique title, since the shared summary controller caches by page.
    private func loadedViewModel(title: String, languageCode: String, languageVariantCode: String?) async -> WMFAsyncPageRowSavedViewModel {
        let project = WMFProject.wikipedia(WMFLanguage(languageCode: languageCode, languageVariantCode: languageVariantCode))
        let viewModel = WMFAsyncPageRowSavedViewModel(id: UUID().uuidString, title: "\(title) \(UUID().uuidString)", project: project, readingListNames: [], localizedStrings: localizedStrings)
        for _ in 0..<50 where viewModel.description == nil {
            try? await Task.sleep(for: .milliseconds(20))
        }
        return viewModel
    }

    func testShowsTheSummaryTitleForLanguageVariants() async {
        let viewModel = await loadedViewModel(title: "兰香如故", languageCode: "zh", languageVariantCode: "zh-Hant-TW")

        XCTAssertEqual(viewModel.description, "změna zákona", "The summary should have loaded")
        XCTAssertEqual(viewModel.displayTitle, "Novela (právo)")
        XCTAssertTrue(viewModel.title.hasPrefix("兰香如故"), "The stored title is kept for opening the article")
    }

    func testKeepsTheStoredTitleForLanguagesWithoutVariants() async {
        for languageCode in ["en", "de"] {
            let viewModel = await loadedViewModel(title: "Cat", languageCode: languageCode, languageVariantCode: nil)

            XCTAssertEqual(viewModel.description, "změna zákona", "The summary should have loaded for \(languageCode)")
            XCTAssertEqual(viewModel.displayTitle, viewModel.title, languageCode)
        }
    }
}
