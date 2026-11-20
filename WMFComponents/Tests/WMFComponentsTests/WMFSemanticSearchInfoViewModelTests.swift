import XCTest
@testable import WMFComponents

@MainActor
final class WMFSemanticSearchInfoViewModelTests: XCTestCase {

    func testLayoutFollowsTheSearchLanguage() {
        XCTAssertTrue(WMFSemanticSearchInfoViewModel(languageCode: "ar", learnMoreAction: {}, closeAction: {}).isRightToLeft)
        XCTAssertFalse(WMFSemanticSearchInfoViewModel(languageCode: "fr", learnMoreAction: {}, closeAction: {}).isRightToLeft)
        XCTAssertFalse(WMFSemanticSearchInfoViewModel(languageCode: nil, learnMoreAction: {}, closeAction: {}).isRightToLeft)
    }

    func testExampleIsAFixedResultInTheSearchLanguage() {
        for languageCode in ["ar", "fr", "ja", "en"] {
            let viewModel = WMFSemanticSearchInfoViewModel(languageCode: languageCode, learnMoreAction: {}, closeAction: {})
            let example = WMFSemanticSearchInfoExample.forLanguage(languageCode)

            XCTAssertEqual(viewModel.exampleQuery, example.query)
            XCTAssertEqual(viewModel.exampleResult.result, example.result)
            XCTAssertEqual(viewModel.exampleResult.project.languageCode, languageCode)
            XCTAssertEqual(viewModel.exampleResult.attribution, example.attribution)
            XCTAssertNotNil(example.thumbnail, "\(languageCode): the bundled thumbnail is missing.")
            XCTAssertTrue(viewModel.exampleResult.thumbnail === example.thumbnail)
            XCTAssertNil(example.result.thumbnailURL, "\(languageCode): the example must not load from the network.")
            XCTAssertFalse(viewModel.exampleResult.showsReadInArticle)
        }
    }

    func testExampleFallsBackToEnglish() {
        let viewModel = WMFSemanticSearchInfoViewModel(languageCode: "de", learnMoreAction: {}, closeAction: {})

        XCTAssertEqual(viewModel.exampleResult.project.languageCode, "en")
    }

    func testActionsCallTheirClosures() {
        var calls: [String] = []
        let viewModel = WMFSemanticSearchInfoViewModel(
            languageCode: "fr",
            learnMoreAction: { calls.append("learnMore") },
            closeAction: { calls.append("close") })

        viewModel.learnMore()
        viewModel.close()

        XCTAssertEqual(calls, ["learnMore", "close"])
    }

    func testSemanticSearchSheetKeepsItsCardAndHasNoTurnOffButton() {
        let viewModel = WMFSemanticSearchInfoViewModel(languageCode: "en", learnMoreAction: {}, closeAction: {})

        XCTAssertFalse(viewModel.showsInterleavedResultsContent)
    }

    func testInterleavedResultsSheetWithoutTurnOffActionKeepsItsContent() {
        let semanticSearchSheet = WMFSemanticSearchInfoViewModel(languageCode: "en", learnMoreAction: {}, closeAction: {})
        let viewModel = WMFSemanticSearchInfoViewModel(languageCode: "en", kind: .interleavedResults(turnOffAction: nil), learnMoreAction: {}, closeAction: {})

        XCTAssertTrue(viewModel.showsInterleavedResultsContent)
        XCTAssertNotEqual(viewModel.summary, semanticSearchSheet.summary)
        XCTAssertNotEqual(viewModel.sourcesDescription, semanticSearchSheet.sourcesDescription)
        viewModel.turnOff()
    }

    func testInterleavedResultsSheetHasItsOwnTextAndATurnOffButton() {
        var calls: [String] = []
        let semanticSearchSheet = WMFSemanticSearchInfoViewModel(languageCode: "en", learnMoreAction: {}, closeAction: {})
        let viewModel = WMFSemanticSearchInfoViewModel(
            languageCode: "en",
            kind: .interleavedResults(turnOffAction: { calls.append("turnOff") }),
            learnMoreAction: { calls.append("learnMore") },
            closeAction: { calls.append("close") })

        XCTAssertTrue(viewModel.showsInterleavedResultsContent)
        XCTAssertNotEqual(viewModel.summary, semanticSearchSheet.summary)
        XCTAssertNotEqual(viewModel.sourcesDescription, semanticSearchSheet.sourcesDescription)
        XCTAssertEqual(viewModel.title, semanticSearchSheet.title)

        viewModel.turnOff()
        viewModel.learnMore()
        viewModel.close()

        XCTAssertEqual(calls, ["turnOff", "learnMore", "close"])
    }

    func testInterleavedExampleIsTheSameResultWithItsCountsAlreadyLoaded() {
        for languageCode in ["ar", "fr", "ja", "en"] {
            let example = WMFSemanticSearchInfoExample.forLanguage(languageCode)
            let viewModel = WMFSemanticSearchInfoViewModel(languageCode: languageCode, kind: .interleavedResults(turnOffAction: {}), learnMoreAction: {}, closeAction: {})
            let row = viewModel.exampleInterleavedRow

            XCTAssertEqual(row.result.title, example.result.title)
            XCTAssertEqual(row.result.sectionTitle, example.result.sectionTitle)
            XCTAssertNotNil(row.result.description, "\(languageCode): the example card needs the short description.")
            XCTAssertEqual(row.result.description, example.result.description)
            XCTAssertEqual(row.result.extract, WMFSemanticSearchSnippet.plainText(html: example.result.snippetHTML))
            XCTAssertNil(row.result.thumbnailURL, "\(languageCode): the example must not load from the network.")
            XCTAssertEqual(row.attributionState, .loaded(example.attribution))
            XCTAssertNotNil(row.contributorsText)
            XCTAssertTrue(viewModel.exampleThumbnail === example.thumbnail)
        }
    }
}
