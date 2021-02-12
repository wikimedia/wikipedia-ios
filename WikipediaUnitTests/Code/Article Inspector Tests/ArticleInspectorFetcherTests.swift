@testable import Wikipedia
@testable import WMF

import XCTest

fileprivate class MockSession: Session {
    
    private let data: Data
    
    required init(configuration: Configuration, data: Data) {
        self.data = data
        super.init(configuration: configuration)
    }
    
    required init(configuration: Configuration) {
        fatalError("init(configuration:) has not been implemented")
    }
    
    override func jsonDecodableTask<T>(with urlRequest: URLRequest, completionHandler: @escaping (T?, URLResponse?, Error?) -> Void) -> URLSessionDataTask? where T : Decodable {
        do {
            let result: SignificantEvents = try jsonDecodeData(data: data)
            completionHandler(result as? T, nil, nil)
        } catch (let error) {
            XCTFail("Significant Events json failed to decode \(error)")
        }
    
        return nil
    }
}

class ArticleInspectorFetcherTests: XCTestCase {
    
    fileprivate var session: MockSession!

    override func setUpWithError() throws {
        
        guard let wikiWhoData = wmf_bundle().wmf_data(fromContentsOfFile: "ArticleInspector-WikiWho", ofType: "json") else {
            XCTFail("Failure setting up MockSession for ArticleInspector")
            return
        }
        
        session = MockSession(configuration: Configuration.current, data: wikiWhoData)
    }

    func testFetchWikiWho() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        
        let siteURL = URL(string: "https://en.wikipedia.org")!
        let title = "United_States"

        let fetcher = ArticleInspectorFetcher(session: session, configuration: Configuration.current)
        fetcher.fetchWikiWho(articleTitle: "Apollo_14") { (result) in
            
            defer {
                fetchExpectation.fulfill()
            }
            
            switch result {
            case .success(let response):
                print("worked")
            case .failure(let error):
                XCTFail("Error fetching : \(error)")
            }
        }
    }

}
