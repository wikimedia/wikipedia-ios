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

        let fetcher = ArticleInspectorFetcher(session: session, configuration: Configuration.current)
        fetcher.fetchWikiWho(articleTitle: "Apollo_14") { (result) in
            
            defer {
                fetchExpectation.fulfill()
            }
            
            switch result {
            case .success(let response):
                XCTAssertNotNil(response.extendedHtml)
                guard let firstRevision = response.revisions["588428499"] else {
                    XCTFail("Unable to pull first revision")
                    return
                }
                
                XCTAssertEqual(firstRevision.revisionID, "588298752")
                XCTAssertEqual(firstRevision.revisionDateString, "2013-12-30T21:47:37Z")
                XCTAssertEqual(firstRevision.editorID, "fc53413bd6044d4e8097b7c420d01ae7")
                XCTAssertEqual(firstRevision.editorName, "0|82.139.164.84")
                
                guard let firstEditor = response.editors.first else {
                    XCTFail("Unable to pull first editor")
                    return
                }
                
                XCTAssertEqual(firstEditor.editorID, "458237")
                XCTAssertEqual(firstEditor.editorName, "Wehwalt")
                XCTAssertEqual(firstEditor.editorPercentage, 58.3406105)
                
                guard let firstToken = response.tokens.first else {
                    XCTFail("Unable to pull first token")
                    return
                }
                
                XCTAssertEqual(firstToken.text, "{{")
                XCTAssertEqual(firstToken.revisionID, "1003198272")
                XCTAssertEqual(firstToken.editorID, "10808929")
            case .failure(let error):
                XCTFail("Error fetching : \(error)")
            }
        }
        
        wait(for: [fetchExpectation], timeout: 10)
    }

}
