import Foundation
import Testing
import WMFData
@testable import Wikipedia

struct InsertMediaSearchViewControllerTests {

    /// A new search cancels the running full text search. The delegate must hear about it, so that it clears the old results.
    @Test
    func cancellationOfTheFullTextSearchReachesTheDelegate() {
        let cancellation = NSError(domain: NSURLErrorDomain, code: NSURLErrorCancelled)

        #expect(InsertMediaSearchViewController.shouldReportFullTextFailure(cancellation))
    }

    /// Any other full text failure keeps the prefix results that are already on screen.
    @Test
    func otherFullTextFailuresKeepTheShownResults() {
        let apiError = WMFDataControllerError.unexpectedResponse
        let networkError = URLError(.notConnectedToInternet)
        let decodingError = DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "not json"))

        #expect(!InsertMediaSearchViewController.shouldReportFullTextFailure(apiError))
        #expect(!InsertMediaSearchViewController.shouldReportFullTextFailure(networkError))
        #expect(!InsertMediaSearchViewController.shouldReportFullTextFailure(decodingError))
    }
}
