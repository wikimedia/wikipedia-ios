
import XCTest
import CoreData
@testable import Wikipedia

class TalkPageLocalHandlerTests: XCTestCase {
    
    let urlString1 = "https://en.wikipedia.org/api/rest_v1/page/talk/Username1"
    let urlString2 = "https://en.wikipedia.org/api/rest_v1/page/talk/Username2"
    let urlString3 = "https://es.wikipedia.org/api/rest_v1/page/talk/Username1"
    
    var tempDataStore: MWKDataStore!
    var moc: NSManagedObjectContext!
    
    override func setUp() {
        super.setUp()
        tempDataStore = MWKDataStore.temporary()
        moc = tempDataStore.viewContext
    }
    
    override func tearDown() {
        tempDataStore.removeFolderAtBasePath()
        tempDataStore = nil
        super.tearDown()
    }
    
    func testCreateFirstTalkPageSavesToDatabase() {
        
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //add network talk page
        guard let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }

        //create db talk page
        guard let dbTalkPage = moc.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //assert db talk page values
        let keyedUrlString = URL(string: urlString1)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(dbTalkPage.key)
        XCTAssertEqual(dbTalkPage.key, keyedUrlString, "Unexpected key")
        XCTAssertEqual(dbTalkPage.revisionId, 1, "Unexpected revisionId")
        XCTAssertEqual(dbTalkPage.topics?.count, 1, "Unexpected topic count")
        
        if let firstTopic = dbTalkPage.topics?.allObjects[0] as? TalkPageTopic {
            XCTAssertEqual(firstTopic.title, "Would you please help me expand the Puppy cat article?", "Unexpected topic title")
            XCTAssertEqual(firstTopic.replies?.count, 2, "Unexpected topic items count")
            
            let replies = firstTopic.replies?.allObjects.sorted{ ($0 as! TalkPageReply).sort < ($1 as! TalkPageReply).sort }
            if let firstReply = replies?[0] as? TalkPageReply {
                XCTAssertEqual(firstReply.text, "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected reply text")
                XCTAssertEqual(firstReply.depth, 0, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected first reply type")
            }
            
            if let secondReply = replies?[1] as? TalkPageReply {
                XCTAssertEqual(secondReply.text, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected reply text")
                XCTAssertEqual(secondReply.depth, 1, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected second reply type")
            }
            
        } else {
            XCTFail("Unexpected first topic type")
        }
        
        //confirm one talk page exists in DB
        guard let secondResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching saved talk pages")
            return
        }
        
        XCTAssertEqual(secondResults.count, 1, "Expected 1 talk page in DB")
        XCTAssertEqual(secondResults.first, dbTalkPage)
    }
    
    func testExistingTalkPagePullsFromDB() {
        
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //add network talk page
        guard let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //create db talk page
        guard let dbTalkPage = moc.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //confirm asking for existing talk page with key pulls same talk page
        guard let existingTalkPage = try? moc.talkPage(for: URL(string: urlString1)!) else {
            XCTFail("Pull existing talk page fails")
            return
        }
        
        XCTAssertEqual(existingTalkPage, dbTalkPage, "Unexpected existing talk page value")
        
        //confirm asking for urlString2 pulls nothing
        do {
            let nonexistantTalkPage = try moc.talkPage(for: URL(string: urlString2)!)
            XCTAssertNil(nonexistantTalkPage)
        } catch {
            XCTFail("Pull existing talk page fails")
        }
    }
    
    func testUpdateExistingTalkPageUpdatesValues() {
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //add network talk page
        guard let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //create db talk page
        guard let dbTalkPage = moc.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //confirm only 2 replies
        if let firstTopic = dbTalkPage.topics?.allObjects[0] as? TalkPageTopic {
            XCTAssertEqual(firstTopic.replies?.count, 2)
        } else {
            XCTFail("Unexpected number of replies")
        }
        
        //get updated talk page
        guard let updatedTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, jsonType: .updated, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        guard let updatedDbTalkPage = moc.updateTalkPage(dbTalkPage, with: updatedTalkPage) else {
            XCTFail("Failure updating existing local talk page")
            return
        }
        
        //confirm 3 topic items
        if let firstTopic = updatedDbTalkPage.topics?.allObjects[0] as? TalkPageTopic {
            XCTAssertEqual(firstTopic.replies?.count, 3)
        } else {
            XCTFail("Unexpected number of replies")
        }
    }
    
    func testPerformanceTestUpdateTalkPages() {
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //add network talk page
        guard let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, jsonType: .largeForPerformance, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //create db talk page
        guard let dbTalkPage = moc.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //confirm 162 topics
        if let topics = dbTalkPage.topics {
            XCTAssertEqual(topics.count, 162)
        } else {
            XCTFail("Unexpected number of topics")
        }
        
        //get updated talk page
        guard let updatedTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, jsonType: .largeUpdatedForPerformance, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        let startTime = CACurrentMediaTime()
        
//        measure {
            guard let updatedDbTalkPage = moc.updateTalkPage(dbTalkPage, with: updatedTalkPage) else {
                XCTFail("Failure updating existing local talk page")
                return
            }
            
            
            let timeElapsed = CACurrentMediaTime() - startTime
            print("🌹elapsed time:  \(timeElapsed)")
    
            if let topics = updatedDbTalkPage.topics {
                XCTAssertEqual(topics.count, 167)
            } else {
                XCTFail("Unexpected number of topics")
            }
 //       }
        
        //confirm 167 topics
//        if let topics = updatedDbTalkPage.topics {
//            XCTAssertEqual(topics.count, 167)
//        } else {
//            XCTFail("Unexpected number of topics")
//        }
    }

}
