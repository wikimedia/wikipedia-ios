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
}
