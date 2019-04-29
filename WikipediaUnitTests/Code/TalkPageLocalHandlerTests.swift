
import XCTest
@testable import Wikipedia

class TalkPageLocalHandlerTests: XCTestCase {
    
    let urlString1 = "https://en.wikipedia.org/api/rest_v1/page/talk/Username1"
    let urlString2 = "https://en.wikipedia.org/api/rest_v1/page/talk/Username2"
    let urlString3 = "https://es.wikipedia.org/api/rest_v1/page/talk/Username1"
    
    var tempDataStore: MWKDataStore!
    var talkPageLocalHandler: TalkPageLocalHandler!
    
    override func setUp() {
        super.setUp()
        tempDataStore = MWKDataStore.temporary()
        talkPageLocalHandler = TalkPageLocalHandler(dataStore: tempDataStore)
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
        guard let dbTalkPage = talkPageLocalHandler.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //assert db talk page values
        let keyedUrlString = URL(string: urlString1)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(dbTalkPage.key)
        XCTAssertEqual(dbTalkPage.key, keyedUrlString, "Unexpected key")
        XCTAssertEqual(dbTalkPage.revisionId, 1, "Unexpected revisionId")
        XCTAssertEqual(dbTalkPage.name, "Pixiu", "Unexpected name")
        XCTAssertEqual(dbTalkPage.discussions?.count, 1, "Unexpected discussion count")
        
        if let firstDiscussion = dbTalkPage.discussions?[0] as? TalkPageDiscussion {
            XCTAssertEqual(firstDiscussion.title, "Would you please help me expand the Puppy cat article?", "Unexpected discussion title")
            XCTAssertEqual(firstDiscussion.items?.count, 2, "Unexpected discussion items count")
            
            if let firstDiscussionItem = firstDiscussion.items?[0] as? TalkPageDiscussionItem {
                XCTAssertEqual(firstDiscussionItem.text, "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last week. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected discussion item text")
                XCTAssertEqual(firstDiscussionItem.depth, 0, "Unexpected discussion item depth")
            } else {
                XCTFail("Unexpected first discussion item type")
            }
            
            if let secondDiscussionItem = firstDiscussion.items?[1] as? TalkPageDiscussionItem {
                XCTAssertEqual(secondDiscussionItem.text, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected discussion item text")
                XCTAssertEqual(secondDiscussionItem.depth, 1, "Unexpected discussion item depth")
            } else {
                XCTFail("Unexpected second discussion item type")
            }
            
        } else {
            XCTFail("Unexpected first discussion type")
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
        guard let dbTalkPage = talkPageLocalHandler.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //confirm asking for existing talk page with key pulls same talk page
        guard let existingTalkPage = try? talkPageLocalHandler.existingTalkPage(for: URL(string: urlString1)!) else {
            XCTFail("Pull existing talk page fails")
            return
        }
        
        XCTAssertEqual(existingTalkPage, dbTalkPage, "Unexpected existing talk page value")
        
        //confirm asking for urlString2 pulls nothing
        do {
            let nonexistantTalkPage = try talkPageLocalHandler.existingTalkPage(for: URL(string: urlString2)!)
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
        guard let dbTalkPage = talkPageLocalHandler.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //confirm only 2 discussion items
        if let firstDiscussion = dbTalkPage.discussions?[0] as? TalkPageDiscussion {
            XCTAssertEqual(firstDiscussion.items?.count, 2)
        } else {
            XCTFail("Unexpected discussion type")
        }
        
        //get updated talk page
        guard let updatedTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, talkPageString: "TalkPageUpdated", revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        guard let updatedDbTalkPage = talkPageLocalHandler.updateExistingTalkPage(existingTalkPage: dbTalkPage, with: updatedTalkPage) else {
            XCTFail("Failure updating existing local talk page")
            return
        }
        
        //confirm 3 discussion items
        if let firstDiscussion = updatedDbTalkPage.discussions?[0] as? TalkPageDiscussion {
            XCTAssertEqual(firstDiscussion.items?.count, 3)
        } else {
            XCTFail("Unexpected discussion type")
        }
    }

}
