//
//  TalkPageControllerTests.swift
//  WikipediaUnitTests
//
//  Created by Toni Sevener on 4/23/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import XCTest
@testable import Wikipedia
@testable import WMF

fileprivate class MockTalkPageFetcher: TalkPageFetcher {
    
    static let urlString = "https://en.wikipedia.org/api/rest_v1/page/talk/Username1"
    
    override func fetchTalkPage(for name: String, host: String, priority: Float = URLSessionTask.defaultPriority, completion: @escaping (NetworkTalkPage?, Error?) -> Void) {
        
        let networkTalkPage = TalkPageTestHelpers.networkTalkPage(for: MockTalkPageFetcher.urlString)
        completion(networkTalkPage, nil)
    }
}

class TalkPageControllerTests: XCTestCase {
    
    var tempDataStore: MWKDataStore!
    var talkPageController: TalkPageController!
    var talkPageFetcher: TalkPageFetcher!

    override func setUp() {
        super.setUp()
        tempDataStore = MWKDataStore.temporary()
        talkPageFetcher = MockTalkPageFetcher(session: Session.shared, configuration: Configuration.current)
        talkPageController = TalkPageController(fetcher: talkPageFetcher, dataStore: tempDataStore)
    }

    override func tearDown() {
        tempDataStore.removeFolderAtBasePath()
        tempDataStore = nil
        super.tearDown()
    }

    func testUpdateOrCreateTalkPageReturnsManagedObjectAndSavesToDb() {
        
        let updateOrCreateExpectation = expectation(description: "Waiting for update or create callback")
        talkPageController.updateOrCreateTalkPage(for: "Username1", host: Configuration.Domain.englishWikipedia) { (talkPage, error) in
            
            updateOrCreateExpectation.fulfill()
            XCTAssertNotNil(talkPage)
            XCTAssertNil(error)
            
            let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
            
            //confirm one talk page exists in DB
            guard let results = try? self.tempDataStore.viewContext.fetch(fetchRequest) else {
                XCTFail("Failure fetching saved talk pages")
                return
            }
            
            XCTAssertEqual(results.count, 1, "Expected 1 talk page in DB")
            XCTAssertEqual(results.first, talkPage)
        }
        
        wait(for: [updateOrCreateExpectation], timeout: 5)
    }

}
