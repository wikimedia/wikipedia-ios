
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
                    
                    let secondSection = viewModel.sections[1]
                    
                    switch secondSection.typedEvents[0] {
                    case .small(let smallEvent):
                        XCTAssertEqual(smallEvent.eventDescription, "2 small changes made", "Unexpected small change event description")

                    default:
                        XCTFail("Unexpected first event type")
                    }
                    
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

                    let fourthSection = viewModel.sections[4]
                    let firstEvent = fourthSection.typedEvents[0]

                    switch firstEvent {
                    case .large(let largeEvent):
                        XCTAssertNil(largeEvent.eventDescription)

                        largeEvent.resetAttributedStringsIfNeededWithTraitCollection(regularTraitCollection, theme: lightTheme)
                        
                        guard let attributedText = largeEvent.eventDescriptionForTraitCollection(regularTraitCollection, theme: lightTheme) else {
                            XCTFail("Expected large event to return eventDescription")
                            return
                        }
                        
                        var attributes = attributedText.attributes(at: 0, effectiveRange: nil)
                        var font = attributes[NSAttributedString.Key.font] as! UIFont
                        var color = attributes[NSAttributedString.Key.foregroundColor] as! UIColor
                        XCTAssertEqual(font.pointSize, 17.0)
                        XCTAssertEqual(font.familyName, ".AppleSystemUIFont")
                        XCTAssertEqual(font.fontName, ".SFUI-Regular")
                        XCTAssertEqual(color, Theme.light.colors.primaryText)

                        //bump up the dynamic type and change theme, confirm font size & color changes

                        let largerTraitCollection = UITraitCollection(preferredContentSizeCategory: UIContentSizeCategory.extraLarge)
                        let darkTheme = Theme.black
                        largeEvent.resetAttributedStringsIfNeededWithTraitCollection(largerTraitCollection, theme: darkTheme)
                        
                        guard let largerAttributedText = largeEvent.eventDescriptionForTraitCollection(largerTraitCollection, theme: darkTheme) else {
                            XCTFail("Expected large event to return eventDescription")
                            return
                        }
                        
                        attributes = largerAttributedText.attributes(at: 0, effectiveRange: nil)
                        font = attributes[NSAttributedString.Key.font] as! UIFont
                        color = attributes[NSAttributedString.Key.foregroundColor] as! UIColor
                        XCTAssertEqual(font.pointSize, 19.0)
                        XCTAssertEqual(font.familyName, ".AppleSystemUIFont")
                        XCTAssertEqual(font.fontName, ".SFUI-Regular")
                        XCTAssertEqual(color, Theme.black.colors.primaryText)
                    default:
                        XCTFail("Unexpected first event type")
                    }
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
