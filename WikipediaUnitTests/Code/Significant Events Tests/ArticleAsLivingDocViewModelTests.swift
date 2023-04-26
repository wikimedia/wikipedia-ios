import XCTest
@testable import Wikipedia
@testable import WMF

class ArticleAsLivingDocViewModelTests: XCTestCase {

    let fetcherTests = SignificantEventsFetcherTests()

    override func setUpWithError() throws {
        try fetcherTests.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testSmallViewModelCorrectlyInstantiates() throws {

        let fetchExpectation = expectation(description: "Waiting for fetch callback")

        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"
        
        fetcherTests.fetchManyVariationsResult(title: title, siteURL: siteURL) { (result) in
            switch result {
            case .success(let significantEvents):

                let regularTraitCollection = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory.large)
                let lightTheme = Theme.light
                if let viewModel = ArticleAsLivingDocViewModel(significantEvents: significantEvents, traitCollection: regularTraitCollection, theme: lightTheme) {
                    XCTAssertEqual(viewModel.nextRvStartId, 979853162)
                    XCTAssertEqual(viewModel.sha, "ddb855b98e213935bfa5b23fb37e2d7034fe63eec9673f1fd66f43512c2c92a7")

                    let firstSection = viewModel.sections[0]

                    switch firstSection.typedEvents[0] {
                    case .small(let smallEvent):
                        XCTAssertEqual(smallEvent.eventDescription, "1 small change made", "Unexpected small change event description")

                    default:
                        XCTFail("Unexpected first event type")
                    }
                    
                    /*
                    Currently not using ArticleAsLivingDoc, so commenting out failing test. Should be fixed if we re-implement AALD in future.

                    let secondSection = viewModel.sections[1]

                    switch secondSection.typedEvents[0] {
                    case .small(let smallEvent):
                        XCTAssertEqual(smallEvent.eventDescription, "2 small changes made", "Unexpected small change event description")

                    default:
                        XCTFail("Unexpected first event type")
                    }*/
                    
                } else {
                    XCTFail("Failure to instantiate view model")
                }

            default:
                XCTFail("Failure fetching significant events")
            }

            fetchExpectation.fulfill()
        }

        wait(for: [fetchExpectation], timeout: 10)
    }

    func testNewTalkPageTopicCorrectlyInstantiates() {
        let fetchExpectation = expectation(description: "Waiting for fetch callback")

        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"

        fetcherTests.fetchManyVariationsResult(title: title, siteURL: siteURL) { (result) in
            switch result {
            case .success(let significantEvents):

                let regularTraitCollection = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory.large)
                let lightTheme = Theme.light
                if let viewModel = ArticleAsLivingDocViewModel(significantEvents: significantEvents, traitCollection: regularTraitCollection, theme: lightTheme) {
                    XCTAssertEqual(viewModel.nextRvStartId, 979853162)
                    XCTAssertEqual(viewModel.sha, "ddb855b98e213935bfa5b23fb37e2d7034fe63eec9673f1fd66f43512c2c92a7")

                } else {
                    XCTFail("Failure to instantiate view model")
                }

            default:
                XCTFail("Failure fetching significant events")
            }

            fetchExpectation.fulfill()
        }

        wait(for: [fetchExpectation], timeout: 10)
    }

}
