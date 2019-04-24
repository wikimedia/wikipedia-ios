//
//  TalkPageFetcherTests.swift
//  Wikipedia
//
//  Created by Toni Sevener on 4/19/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import XCTest
@testable import Wikipedia
@testable import WMF

fileprivate class MockSession: Session {
    override public func jsonDecodableTask<T: Decodable>(with url: URL?, method: Session.Request.Method = .get, bodyParameters: Any? = nil, bodyEncoding: Session.Request.Encoding = .json, headers: [String: String] = [:], priority: Float = URLSessionTask.defaultPriority, completionHandler: @escaping (_ result: T?, _ response: URLResponse?,  _ error: Error?) -> Swift.Void) {
        //todo: better bundle pulling
        guard let json = Bundle(identifier: "org.wikimedia.WikipediaUnitTests")?.wmf_data(fromContentsOfFile: "TalkPage", ofType: "json") else {
            XCTFail("Failure pulling local talk page json")
            return
        }
        do {
            let result: NetworkTalkPage = try jsonDecodeData(data: json)
            completionHandler(result as? T, nil, nil)
        } catch (let error) {
            XCTFail("Talk Page json failed to decode \(error)")
        }
    }
}

class TalkPageFetcherTests: XCTestCase {

    fileprivate let mockSession = MockSession(configuration: Configuration.current)
    
    func testTalkPageFetchReturnsTalkPage() {
        let fetcher = TalkPageFetcher(session: mockSession, configuration: Configuration.current)
        
        let fetchExpectation = expectation(description: "Waiting for fetch callback")
        fetcher.fetchTalkPage(for: "Username", host: Configuration.Domain.englishWikipedia) { (talkPage, error) in
            fetchExpectation.fulfill()
            XCTAssertNotNil(talkPage)
            XCTAssertEqual(talkPage?.url.absoluteString, "https://en.wikipedia.org/api/rest_v1/page/talk/Username")
            XCTAssertNil(error)
        }
        wait(for: [fetchExpectation], timeout: 5)
    }
}


