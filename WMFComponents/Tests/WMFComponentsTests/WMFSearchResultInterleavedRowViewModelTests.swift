import XCTest
@testable import WMFComponents
import WMFData

@MainActor
final class WMFSearchResultInterleavedRowViewModelTests: XCTestCase {

    private typealias SearchResult = WMFSearchResultsViewModel.SearchResult
    private typealias RowViewModel = WMFSearchResultInterleavedRowViewModel

    private actor RequestedTitles {
        private(set) var values: [String] = []

        func append(_ title: String) {
            values.append(title)
        }
    }

    private let strings = RowViewModel.LocalizedStrings(
        readInArticleTitle: "Read in article",
        contributorsFormat: "%1$d contributors",
        referencesFormat: "%1$d references",
        lastUpdatedFormat: "Last updated %1$@",
        leadSectionTitle: "Lead")

    private let frenchProject = WMFProject.wikipedia(WMFLanguage(languageCode: "fr", languageVariantCode: nil))
    private let lastUpdated = Date(timeIntervalSince1970: 1_790_329_445)

    private func makeResult(title: String = "Chat", description: String? = nil, extract: String? = nil, sectionTitle: String? = nil) -> SearchResult {
        SearchResult(
            articleURL: URL(string: "https://fr.wikipedia.org/wiki/\(title)")!,
            pageTitle: title,
            title: title,
            titleHTML: title,
            description: description,
            extract: extract,
            sectionTitle: sectionTitle,
            thumbnailURL: nil)
    }

    private func makeViewModel(
        result: SearchResult? = nil,
        showsLastUpdated: Bool = false,
        attribution: WMFSemanticSearchAttribution? = nil,
        requested: RequestedTitles = RequestedTitles()
    ) -> RowViewModel {
        RowViewModel(
            result: result ?? makeResult(),
            project: frenchProject,
            showsLastUpdatedInPlaceOfReferences: showsLastUpdated,
            attributionProvider: { _, title in
                await requested.append(title)
                guard let attribution else { throw URLError(.notConnectedToInternet) }
                return attribution
            },
            localizedStrings: strings)
    }

    // MARK: - Loading

    func testStartsLoadingAndKeepsItsRow() {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.attributionState, .loading)
        XCTAssertTrue(viewModel.showsAttributionRow, "The row keeps its space while the counts load")
        XCTAssertNil(viewModel.contributorsText)
    }

    func testLoadAsksForTheArticleOnceAndKeepsTheCounts() async {
        let requested = RequestedTitles()
        let attribution = WMFSemanticSearchAttribution(contributorCount: 12, referenceCount: 3, lastUpdated: nil)
        let viewModel = makeViewModel(attribution: attribution, requested: requested)

        await viewModel.loadAttribution()
        await viewModel.loadAttribution()

        XCTAssertEqual(viewModel.attributionState, .loaded(attribution))
        let titles = await requested.values
        XCTAssertEqual(titles, ["Chat"], "A loaded card does not ask again")
    }

    func testAFailedRequestEndsLoadingWithNothingToShow() async {
        let viewModel = makeViewModel(attribution: nil)

        await viewModel.loadAttribution()

        XCTAssertEqual(viewModel.attributionState, .loaded(nil))
        XCTAssertFalse(viewModel.showsAttributionRow, "A card without any figure gives its row back")
    }

    // MARK: - Figures

    func testReferenceWikisShowContributorsAndReferencesOnly() async {
        let attribution = WMFSemanticSearchAttribution(contributorCount: 6337, referenceCount: 266, lastUpdated: lastUpdated)
        let viewModel = makeViewModel(showsLastUpdated: false, attribution: attribution)

        await viewModel.loadAttribution()

        XCTAssertNotNil(viewModel.contributorsText)
        XCTAssertNotNil(viewModel.referencesText)
        XCTAssertNil(viewModel.lastUpdatedText, "The date is never the second figure on these wikis")
    }

    func testLastUpdatedWikisShowContributorsAndTheDateOnly() async {
        let attribution = WMFSemanticSearchAttribution(contributorCount: 243, referenceCount: 464, lastUpdated: lastUpdated)
        let viewModel = makeViewModel(showsLastUpdated: true, attribution: attribution)

        await viewModel.loadAttribution()

        XCTAssertNotNil(viewModel.contributorsText)
        XCTAssertNil(viewModel.referencesText, "The reference count is never shown on these wikis")
        XCTAssertTrue(viewModel.lastUpdatedText?.hasPrefix("Last updated ") == true)
    }

    func testAMissingFigureIsHiddenAndTheOthersStay() async {
        let attribution = WMFSemanticSearchAttribution(contributorCount: 5, referenceCount: nil, lastUpdated: nil)
        let viewModel = makeViewModel(attribution: attribution)

        await viewModel.loadAttribution()

        XCTAssertNotNil(viewModel.contributorsText)
        XCTAssertNil(viewModel.referencesText)
        XCTAssertTrue(viewModel.showsAttributionRow)
    }

    // MARK: - Section

    func testResultsWithoutASectionComeFromTheLeadSection() {
        XCTAssertEqual(makeViewModel(result: makeResult(sectionTitle: nil)).displayedSectionTitle, "Lead")
        XCTAssertEqual(makeViewModel(result: makeResult(sectionTitle: "")).displayedSectionTitle, "Lead")
        XCTAssertEqual(makeViewModel(result: makeResult(sectionTitle: "Vision")).displayedSectionTitle, "Vision")
    }

    // MARK: - VoiceOver

    func testAccessibilityTextReadsTheWholeCardInTheLanguageOfTheWiki() async {
        let attribution = WMFSemanticSearchAttribution(contributorCount: 12, referenceCount: 3, lastUpdated: nil)
        let result = makeResult(title: "Chat", description: "Petit mammifère", extract: "Le chat est un félin.", sectionTitle: "Vision")
        let viewModel = makeViewModel(result: result, attribution: attribution)
        await viewModel.loadAttribution()

        let text = viewModel.accessibilityText

        XCTAssertEqual(String(text.characters), "Chat, Petit mammifère, Vision, Le chat est un félin., Read in article, 12 contributors, 3 references")
        XCTAssertEqual(text.languageIdentifier, "fr")
    }

    func testAccessibilityTextLeavesOutWhatTheCardDoesNotShow() {
        let viewModel = makeViewModel(result: makeResult(title: "Chat"))

        XCTAssertEqual(String(viewModel.accessibilityText.characters), "Chat, Lead, Read in article")
    }
}
