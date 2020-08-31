
import XCTest
@testable import Wikipedia

class SignificantEventsViewModelTests: XCTestCase {
    
    let fetcherTests = SignificantEventsFetcherTests()

    override func setUpWithError() throws {
        try fetcherTests.setUpWithError()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testViewModelCorrectlyInstantiates() throws {
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"
        
        fetcherTests.fetchFirstPageResult(title: title, siteURL: siteURL) { (result) in
            switch result {
            case .success(let significantEvents):
                
                if let viewModel = SignificantEventsViewModel(significantEvents: significantEvents) {
                    print(viewModel)
                }
                
            default:
                XCTFail("Failure fetching significant events")
            }
            
            fetchExpectation.fulfill()
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }

}
