import XCTest
@testable import WMFComponents
import WMFData

@MainActor
final class WMFSearchResultsViewModelTests: XCTestCase {

    private typealias SearchResult = WMFSearchResultsViewModel.SearchResult

    private struct RecordedActions {
        var tapped: [(SearchResult, Int)] = []
        var opened: [(SearchResult, Int)] = []
        var openedInNewTab: [(SearchResult, Int)] = []
        var openedInBackgroundTab: [(SearchResult, Int)] = []
        var openedOnMap: [(SearchResult, Int)] = []
        var savedOrUnsaved: [(SearchResult, Int, WMFSearchResultsViewModel.ActionSource)] = []
        var shared: [(SearchResult, Int, CGRect?, WMFSearchResultsViewModel.ActionSource)] = []
    }

    private final class Recorder {
        var actions = RecordedActions()
        var savedURLs: Set<URL> = []
    }

    private let localizedStrings = WMFSearchResultsViewModel.LocalizedStrings(
        openActionTitle: "Open",
        openInNewTabActionTitle: "Open in new tab",
        openInBackgroundTabActionTitle: "Open in background tab",
        saveActionTitle: "Save for later",
        unsaveActionTitle: "Remove from saved",
        shareActionTitle: "Share…",
        viewOnMapActionTitle: "View on a map",
        noResultsMessage: "No results found",
        noInternetConnectionTitle: "No internet connection"
    )

    private func makeResult(_ title: String, titleHTML: String? = nil, isArticle: Bool = true, hasLocation: Bool = false, isSavable: Bool = true) -> SearchResult {
        let encodedTitle = title.replacingOccurrences(of: " ", with: "_")
        return SearchResult(
            articleURL: URL(string: "https://en.wikipedia.org/wiki/\(encodedTitle)")!,
            title: title,
            titleHTML: titleHTML ?? title,
            description: nil,
            thumbnailURL: nil,
            isArticle: isArticle,
            hasLocation: hasLocation,
            isSavable: isSavable)
    }

    private let englishProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))

    private func makeViewModel(recorder: Recorder, summaryProvider: @escaping WMFSearchResultsViewModel.SummaryProvider = { _, _ in throw URLError(.notConnectedToInternet) }) -> WMFSearchResultsViewModel {
        WMFSearchResultsViewModel(
            localizedStrings: localizedStrings,
            noInternetConnectionImage: nil,
            isSavedAction: { recorder.savedURLs.contains($0.articleURL) },
            tapAction: { recorder.actions.tapped.append(($0, $1)) },
            openAction: { recorder.actions.opened.append(($0, $1)) },
            openInNewTabAction: { recorder.actions.openedInNewTab.append(($0, $1)) },
            openInBackgroundTabAction: { recorder.actions.openedInBackgroundTab.append(($0, $1)) },
            openOnMapAction: { recorder.actions.openedOnMap.append(($0, $1)) },
            saveOrUnsaveAction: { recorder.actions.savedOrUnsaved.append(($0, $1, $2)) },
            shareAction: { recorder.actions.shared.append(($0, $1, $2, $3)) },
            summaryProvider: summaryProvider)
    }

    // MARK: - State

    func testShowResultsPopulatesResultsAndClearsEmptyState() {
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder)
        viewModel.showEmptyState(.noInternetConnection)

        viewModel.showResults([makeResult("Cat"), makeResult("Dog")], searchTerm: "ca", project: englishProject)

        XCTAssertEqual(viewModel.results.map(\.title), ["Cat", "Dog"])
        XCTAssertEqual(viewModel.searchTerm, "ca")
        XCTAssertNil(viewModel.emptyState)
        XCTAssertFalse(viewModel.isRightToLeft)
    }

    func testShowResultsWithNoResultsShowsNoResultsState() {
        let viewModel = makeViewModel(recorder: Recorder())

        viewModel.showResults([], searchTerm: "zzz", project: WMFProject.wikipedia(WMFLanguage(languageCode: "ar", languageVariantCode: nil)))

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.emptyState, .noResults)
        XCTAssertTrue(viewModel.isRightToLeft)
    }

    func testShowEmptyStateClearsResults() {
        let viewModel = makeViewModel(recorder: Recorder())
        viewModel.showResults([makeResult("Cat")], searchTerm: "cat", project: englishProject)

        viewModel.showEmptyState(.noInternetConnection)

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertEqual(viewModel.emptyState, .noInternetConnection)
    }

    func testResetClearsEverything() {
        let viewModel = makeViewModel(recorder: Recorder())
        viewModel.showResults([makeResult("Cat")], searchTerm: "cat", project: englishProject)

        viewModel.reset()

        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertNil(viewModel.searchTerm)
        XCTAssertNil(viewModel.emptyState)
    }

    // MARK: - Saved state

    func testShowResultsReadsSavedStateFromClosure() {
        let recorder = Recorder()
        let cat = makeResult("Cat")
        recorder.savedURLs = [cat.articleURL]
        let viewModel = makeViewModel(recorder: recorder)

        viewModel.showResults([cat, makeResult("Dog")], searchTerm: nil, project: englishProject)

        XCTAssertEqual(viewModel.results.map(\.isSaved), [true, false])
    }

    func testRefreshSavedStatesUpdatesChangedRows() {
        let recorder = Recorder()
        let cat = makeResult("Cat")
        let dog = makeResult("Dog")
        let viewModel = makeViewModel(recorder: recorder)
        viewModel.showResults([cat, dog], searchTerm: nil, project: englishProject)

        recorder.savedURLs = [dog.articleURL]
        viewModel.refreshSavedStates()

        XCTAssertEqual(viewModel.results.map(\.isSaved), [false, true])
    }

    // MARK: - Actions carry the row position

    func testActionsForwardResultAndPosition() {
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder)
        let dog = makeResult("Dog")
        viewModel.showResults([makeResult("Cat"), dog], searchTerm: nil, project: englishProject)
        viewModel.geometryFrames[dog.id] = CGRect(x: 0, y: 60, width: 320, height: 60)

        viewModel.tap(dog)
        viewModel.open(dog)
        viewModel.openInNewTab(dog)
        viewModel.openInBackgroundTab(dog)
        viewModel.openOnMap(dog)
        viewModel.saveOrUnsave(dog, source: .contextMenu)
        viewModel.share(dog, source: .swipe)

        XCTAssertEqual(recorder.actions.tapped.map(\.1), [1])
        XCTAssertEqual(recorder.actions.tapped.first?.0.title, "Dog")
        XCTAssertEqual(recorder.actions.opened.map(\.1), [1])
        XCTAssertEqual(recorder.actions.openedInNewTab.map(\.1), [1])
        XCTAssertEqual(recorder.actions.openedInBackgroundTab.map(\.1), [1])
        XCTAssertEqual(recorder.actions.openedOnMap.map(\.1), [1])
        XCTAssertEqual(recorder.actions.savedOrUnsaved.map(\.1), [1])
        XCTAssertEqual(recorder.actions.savedOrUnsaved.first?.2, .contextMenu)
        XCTAssertEqual(recorder.actions.shared.map(\.1), [1])
        XCTAssertEqual(recorder.actions.shared.first?.2, CGRect(x: 0, y: 60, width: 320, height: 60))
        XCTAssertEqual(recorder.actions.shared.first?.3, .swipe)
    }

    func testActionsIgnoreResultsNoLongerDisplayed() {
        let recorder = Recorder()
        let viewModel = makeViewModel(recorder: recorder)
        let cat = makeResult("Cat")
        viewModel.showResults([cat], searchTerm: nil, project: englishProject)
        viewModel.reset()

        viewModel.tap(cat)
        viewModel.share(cat, source: .swipe)

        XCTAssertTrue(recorder.actions.tapped.isEmpty)
        XCTAssertTrue(recorder.actions.shared.isEmpty)
    }

    // MARK: - Description

    func testDisplayedDescriptionKeepsOnlyTheFirstLine() {
        let redirected = SearchResult(
            articleURL: URL(string: "https://en.wikipedia.org/wiki/The_Subdudes")!,
            title: "The Subdudes",
            titleHTML: "The Subdudes",
            description: "Redirected from: Tim Cook (musician)\nAmerican band",
            thumbnailURL: nil)
        let plain = makeResult("Cat")

        XCTAssertEqual(redirected.displayedDescription, "Redirected from: Tim Cook (musician)")
        XCTAssertEqual(redirected.description, "Redirected from: Tim Cook (musician)\nAmerican band")
        XCTAssertNil(plain.displayedDescription)
    }

    // MARK: - Preview

    private var catResult: SearchResult {
        SearchResult(
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Cat")!,
            title: "Cat",
            titleHTML: "<i>Cat</i>",
            description: "Redirected from: Felis\nSmall domesticated animal",
            thumbnailURL: URL(string: "https://upload.wikimedia.org/cat-120.jpg"))
    }

    func testPreviewUsesTheSummaryWhenItLoads() async {
        let summary = WMFArticleSummary(displayTitle: "Cat", description: "Small domesticated carnivorous mammal", extractHtml: "", thumbnailURL: URL(string: "https://upload.wikimedia.org/cat-320.jpg"), extract: "The cat is a small domesticated carnivorous mammal.")
        let viewModel = makeViewModel(recorder: Recorder(), summaryProvider: { _, _ in summary })
        viewModel.showResults([catResult], searchTerm: nil, project: englishProject)

        let preview = await viewModel.loadPreviewViewModel(for: viewModel.results[0])

        XCTAssertEqual(preview.url, catResult.articleURL)
        XCTAssertEqual(preview.titleHtml, "Cat")
        XCTAssertEqual(preview.description, "Small domesticated carnivorous mammal")
        XCTAssertEqual(preview.imageURL?.absoluteString, "https://upload.wikimedia.org/cat-320.jpg")
        XCTAssertEqual(preview.snippet, "The cat is a small domesticated carnivorous mammal.")
    }

    func testPreviewFallsBackToTheRowDataWhenTheSummaryFails() async {
        let viewModel = makeViewModel(recorder: Recorder())
        viewModel.showResults([catResult], searchTerm: nil, project: englishProject)

        let preview = await viewModel.loadPreviewViewModel(for: viewModel.results[0])

        XCTAssertEqual(preview.titleHtml, "Cat")
        XCTAssertEqual(preview.description, "Redirected from: Felis")
        XCTAssertEqual(preview.imageURL?.absoluteString, "https://upload.wikimedia.org/cat-120.jpg")
        XCTAssertNil(preview.snippet)
    }

    // MARK: - Face crop

    func testSquareCropRectCentersOnTheFace() {
        let rect = WMFSearchResultsViewModel.squareCropRect(imageSize: CGSize(width: 120, height: 200), faceUnitRect: CGRect(x: 0.3, y: 0.4, width: 0.4, height: 0.2))

        XCTAssertEqual(rect, CGRect(x: 0, y: 40, width: 120, height: 120))
    }

    func testSquareCropRectClampsToTheImageEdges() {
        let top = WMFSearchResultsViewModel.squareCropRect(imageSize: CGSize(width: 120, height: 200), faceUnitRect: CGRect(x: 0.3, y: 0.0, width: 0.4, height: 0.2))
        let bottom = WMFSearchResultsViewModel.squareCropRect(imageSize: CGSize(width: 120, height: 200), faceUnitRect: CGRect(x: 0.3, y: 0.8, width: 0.4, height: 0.2))
        let landscape = WMFSearchResultsViewModel.squareCropRect(imageSize: CGSize(width: 300, height: 100), faceUnitRect: CGRect(x: 0.9, y: 0.2, width: 0.1, height: 0.5))

        XCTAssertEqual(top, CGRect(x: 0, y: 0, width: 120, height: 120))
        XCTAssertEqual(bottom, CGRect(x: 0, y: 80, width: 120, height: 120))
        XCTAssertEqual(landscape, CGRect(x: 200, y: 0, width: 100, height: 100))
    }

    // MARK: - Title

    private var titleStyles: HtmlUtils.Styles {
        HtmlUtils.Styles(
            font: WMFFont.for(.callout),
            boldFont: WMFFont.for(.boldCallout),
            italicsFont: WMFFont.for(.italicCallout),
            boldItalicsFont: WMFFont.for(.boldItalicCallout),
            color: .black,
            linkColor: .blue,
            lineSpacing: 1)
    }

    func testAttributedTitleBoldsSearchTermCaseInsensitively() {
        let viewModel = makeViewModel(recorder: Recorder())
        let result = makeResult("Communication studies")
        viewModel.showResults([result], searchTerm: "COMMUNI", project: englishProject)
        let boldFont = WMFFont.for(.boldCallout)

        let attributedTitle = viewModel.attributedTitle(for: result, styles: titleStyles, boldFont: boldFont)

        XCTAssertEqual(String(attributedTitle.characters), "Communication studies")
        let boldRange = attributedTitle.range(of: "Communi")!
        XCTAssertEqual(attributedTitle[boldRange].font, boldFont)
        let plainRange = attributedTitle.range(of: "studies")!
        XCTAssertEqual(attributedTitle[plainRange].font, titleStyles.font)
    }

    func testAttributedTitleStripsHTMLBeforeBolding() {
        let viewModel = makeViewModel(recorder: Recorder())
        let result = makeResult("Felis catus", titleHTML: "<i>Felis</i> catus")
        viewModel.showResults([result], searchTerm: "felis", project: englishProject)

        let attributedTitle = viewModel.attributedTitle(for: result, styles: titleStyles, boldFont: WMFFont.for(.boldCallout))

        XCTAssertEqual(String(attributedTitle.characters), "Felis catus")
        XCTAssertNotNil(attributedTitle.range(of: "Felis"))
    }

    func testAttributedTitleWithoutSearchTermKeepsRegularFont() {
        let viewModel = makeViewModel(recorder: Recorder())
        let result = makeResult("Cat")
        viewModel.showResults([result], searchTerm: nil, project: englishProject)

        let attributedTitle = viewModel.attributedTitle(for: result, styles: titleStyles, boldFont: WMFFont.for(.boldCallout))

        XCTAssertEqual(attributedTitle.runs.count, 1)
        XCTAssertEqual(attributedTitle.font, titleStyles.font)
    }

    func testAccessibilityTextCarriesTheProjectLanguage() {
        let viewModel = makeViewModel(recorder: Recorder())
        let result = makeResult("Gato")
        viewModel.showResults([result], searchTerm: nil, project: WMFProject.wikipedia(WMFLanguage(languageCode: "pt", languageVariantCode: nil)))

        let attributedTitle = viewModel.attributedTitle(for: result, styles: titleStyles, boldFont: WMFFont.for(.boldCallout))
        let accessibilityDescription = viewModel.accessibilityText("Mamífero carnívoro")

        XCTAssertEqual(attributedTitle.languageIdentifier, "pt")
        XCTAssertEqual(accessibilityDescription.languageIdentifier, "pt")
        XCTAssertEqual(String(accessibilityDescription.characters), "Mamífero carnívoro")
    }
}
