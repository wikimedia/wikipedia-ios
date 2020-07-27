
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
        guard let json = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.original.fileName, ofType: "json"),
            let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: json, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }

        //create db talk page
        guard let dbTalkPage = moc.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //assert db talk page values
        let keyedUrlString = URL(string: urlString1)?.wmf_databaseKey
        XCTAssertNotNil(dbTalkPage.key)
        XCTAssertEqual(dbTalkPage.key, keyedUrlString, "Unexpected key")
        XCTAssertEqual(dbTalkPage.revisionId, 1, "Unexpected revisionId")
        XCTAssertEqual(dbTalkPage.topics?.count, 6, "Unexpected topic count")
        
        let topics = dbTalkPage.topics?.allObjects.sorted{ ($0 as! TalkPageTopic).sort < ($1 as! TalkPageTopic).sort }
        
        if let introTopic = topics?[0] as? TalkPageTopic {
            XCTAssertEqual(introTopic.title, "", "Unexpected topic title")
            XCTAssertEqual(introTopic.replies?.count, 1, "Unexpected replies count")
            let replies = introTopic.replies?.allObjects.sorted{ ($0 as! TalkPageReply).sort < ($1 as! TalkPageReply).sort }
            if let firstReply = replies?[0] as? TalkPageReply {
                XCTAssertEqual(firstReply.text, "Hello!  This is some introduction text on my talk page. L8erz, <a href='./User:TSevener_(WMF)' title='User:TSevener (WMF)'>TSevener (WMF)</a> (<a href='./User_talk:TSevener_(WMF)' title='User talk:TSevener (WMF)'>talk</a>) 20:48, 21 June 2019 (UTC)", "Unexpected replies html")
            } else {
                XCTFail("Unexpected first reply type")
            }
        } else {
            XCTFail("Unexpected intro topic type")
        }
        
        if let firstTopic = topics?[1] as? TalkPageTopic {
            XCTAssertEqual(firstTopic.title, "Let’s talk about talk pages", "Unexpected topic title")
            XCTAssertEqual(firstTopic.replies?.count, 3, "Unexpected topic items count")
            
            let replies = firstTopic.replies?.allObjects.sorted{ ($0 as! TalkPageReply).sort < ($1 as! TalkPageReply).sort }
            if let firstReply = replies?[0] as? TalkPageReply {
                XCTAssertEqual(firstReply.text, "Hello, I am testing a new topic from the <a href='./IOS' title='IOS'>iOS</a> app. It is fun. <a href='./Special:Contributions/47.184.10.84' title='Special:Contributions/47.184.10.84'>47.184.10.84</a> 20:50, 21 June 2019 (UTC)")
                XCTAssertEqual(firstReply.depth, 0, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected first reply type")
            }
            
            if let secondReply = replies?[1] as? TalkPageReply {
                XCTAssertEqual(secondReply.text, "Hello back! This is a nested reply. <a href='./User:TSevener_(WMF)' title='User:TSevener (WMF)'>TSevener (WMF)</a> (<a href='./User_talk:TSevener_(WMF)' title='User talk:TSevener (WMF)'>talk</a>) 20:51, 21 June 2019 (UTC)")
                XCTAssertEqual(secondReply.depth, 1, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected second reply type")
            }
            
            if let thirdReply = replies?[2] as? TalkPageReply {
                XCTAssertEqual(thirdReply.text, "Yes I see, I am nested as well. <a href='./Special:Contributions/47.184.10.84' title='Special:Contributions/47.184.10.84'>47.184.10.84</a> 20:52, 21 June 2019 (UTC)")
                XCTAssertEqual(thirdReply.depth, 2, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected third reply type")
            }
            
        } else {
            XCTFail("Unexpected first topic type")
        }
        
        if let secondTopic = topics?[2] as? TalkPageTopic {
            XCTAssertEqual(secondTopic.title, "Subtopic time")
            XCTAssertEqual(secondTopic.replies?.count, 2, "Unexpected topic items count")
        }
        
        if let thirdTopic = topics?[3] as? TalkPageTopic {
            XCTAssertEqual(thirdTopic.title, "Sub sub topic")
            XCTAssertEqual(thirdTopic.replies?.count, 2, "Unexpected topic items count")
        }
        
        if let fourthTopic = topics?[4] as? TalkPageTopic {
            XCTAssertEqual(fourthTopic.title, "Topic <a href='./Part' title='Part'>Part</a> Deux")
            XCTAssertEqual(fourthTopic.replies?.count, 9, "Unexpected topic items count")
        }
        
        if let fifthTopic = topics?[5] as? TalkPageTopic {
            XCTAssertEqual(fifthTopic.title, "Topic <a href='./Part' title='Part'>Part</a> Trois")
            XCTAssertEqual(fifthTopic.replies?.count, 1, "Unexpected topic items count")
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
        guard let json = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.original.fileName, ofType: "json"),
            let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: json, revisionId: 1) else {
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
        guard let originalJson = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.original.fileName, ofType: "json"),
            let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: originalJson, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //create db talk page
        guard let dbTalkPage = moc.createTalkPage(with: talkPage) else {
            XCTFail("Failure to create db talk page")
            return
        }
        
        //mark last topic as read to confirm it stays read after updating.
        let topics = dbTalkPage.topics?.allObjects.sorted{ ($0 as! TalkPageTopic).sort < ($1 as! TalkPageTopic).sort }
        if let fifthTopic = topics?[5] as? TalkPageTopic {
            fifthTopic.content?.isRead = true
            do {
                try moc.save()
            } catch {
                XCTFail("Failure to save isRead flag")
            }
        }
        
        //get updated talk page payload
        guard let updatedJson = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.updated.fileName, ofType: "json"),
            let updatedTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: updatedJson, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //update local talk page with new talk page
        guard let updatedDbTalkPage = moc.updateTalkPage(dbTalkPage, with: updatedTalkPage) else {
            XCTFail("Failure updating existing local talk page")
            return
        }
        
        XCTAssertEqual(updatedDbTalkPage.topics?.count, 3, "Unexpected topic count")
        
        let updatedTopics = updatedDbTalkPage.topics?.allObjects.sorted{ ($0 as! TalkPageTopic).sort < ($1 as! TalkPageTopic).sort }
        
        if let introTopic = updatedTopics?[0] as? TalkPageTopic {
            XCTAssertEqual(introTopic.title, "", "Unexpected topic title")
            XCTAssertEqual(introTopic.replies?.count, 1, "Unexpected replies count")
            let replies = introTopic.replies?.allObjects.sorted{ ($0 as! TalkPageReply).sort < ($1 as! TalkPageReply).sort }
            if let firstReply = replies?[0] as? TalkPageReply {
                XCTAssertEqual(firstReply.text, "Hello!  This is some introduction text on my talk page. L8erz, <a href='./User:TSevener_(WMF)' title='User:TSevener (WMF)'>TSevener (WMF)</a> (<a href='./User_talk:TSevener_(WMF)' title='User talk:TSevener (WMF)'>talk</a>) 20:48, 21 June 2019 (UTC)", "Unexpected replies html")
            } else {
                XCTFail("Unexpected first reply type")
            }
        } else {
            XCTFail("Unexpected intro topic type")
        }
        
        if let firstTopic = updatedTopics?[1] as? TalkPageTopic {
            XCTAssertEqual(firstTopic.title, "Topic <a href='./Part' title='Part'>Part</a> Deux", "Unexpected topic title")
            XCTAssertEqual(firstTopic.replies?.count, 11, "Unexpected topic items count")
            
            let replies = firstTopic.replies?.allObjects.sorted{ ($0 as! TalkPageReply).sort < ($1 as! TalkPageReply).sort }
            if let firstReply = replies?[0] as? TalkPageReply {
                XCTAssertEqual(firstReply.text, "Also injecting something in the front because why not. 🤷‍♀️ <a href='./User:TSevener_(WMF)' title='User:TSevener (WMF)'>TSevener (WMF)</a> (<a href='./User_talk:TSevener_(WMF)' title='User talk:TSevener (WMF)'>talk</a>) 21:17, 21 June 2019 (UTC)")
                XCTAssertEqual(firstReply.depth, 0, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected first reply type")
            }
            
            if let secondReply = replies?[1] as? TalkPageReply {
                XCTAssertEqual(secondReply.text, "Ok try this on for size - can you put a link in a topic title from the iOS app? Only time will tell. <a href='./Special:Contributions/47.184.10.84' title='Special:Contributions/47.184.10.84'>47.184.10.84</a> 20:57, 21 June 2019 (UTC)")
                XCTAssertEqual(secondReply.depth, 0, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected second reply type")
            }
            
            if let thirdReply = replies?[2] as? TalkPageReply {
                XCTAssertEqual(thirdReply.text, "It certainly seems so. It is good we tested this my friend. <a href='./User:TSevener_(WMF)' title='User:TSevener (WMF)'>TSevener (WMF)</a> (<a href='./User_talk:TSevener_(WMF)' title='User talk:TSevener (WMF)'>talk</a>) 20:58, 21 June 2019 (UTC)")
                XCTAssertEqual(thirdReply.depth, 1, "Unexpected reply depth")
            } else {
                XCTFail("Unexpected third reply type")
            }
            
        } else {
            XCTFail("Unexpected first topic type")
        }
        
        if let secondTopic = updatedTopics?[2] as? TalkPageTopic {
            XCTAssertEqual(secondTopic.title, "Topic <a href='./Part' title='Part'>Part</a> Trois")
            XCTAssertEqual(secondTopic.replies?.count, 1, "Unexpected topic items count")
            XCTAssertTrue(secondTopic.content?.isRead ?? false, "isRead flag flipped back to false after reorder.")
        }
        
        //confirm one talk page exists in DB
        guard let secondResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching saved talk pages")
            return
        }
        
        XCTAssertEqual(secondResults.count, 1, "Expected 1 talk page in DB")
        XCTAssertEqual(secondResults.first, dbTalkPage)
    }
}
