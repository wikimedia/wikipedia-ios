//
//  TalkPageLocalDataTests.swift
//  WikipediaUnitTests
//
//  Created by Toni Sevener on 4/23/19.
//  Copyright © 2019 Wikimedia Foundation. All rights reserved.
//

import XCTest
@testable import Wikipedia
@testable import WMF

class TalkPageLocalDataTests: XCTestCase {
    
    let urlString1 = "https://en.wikipedia.org/api/rest_v1/page/talk/Username1"
    let urlString2 = "https://en.wikipedia.org/api/rest_v1/page/talk/Username2"
    let urlString3 = "https://es.wikipedia.org/api/rest_v1/page/talk/Username1"
    
    var tempDataStore: MWKDataStore!

    override func setUp() {
        super.setUp()
        tempDataStore = MWKDataStore.temporary()
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
        guard let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //create db talk page
        var dbTalkPage: TalkPage?
        do {
            dbTalkPage = try tempDataStore.viewContext.wmf_createOrUpdateTalkPage(talkPage: talkPage)
        } catch (let error) {
            XCTFail("Create Or Update Talk Page call failed: \(error)")
        }
        
        //assert db talk page values
        let keyedUrlString = URL(string: urlString1)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(dbTalkPage?.key)
        XCTAssertEqual(dbTalkPage?.key, keyedUrlString, "Unexpected key")
        XCTAssertEqual(dbTalkPage?.revisionId, 0, "Unexpected revisionId")
        XCTAssertEqual(dbTalkPage?.name, "Pixiu", "Unexpected name")
        XCTAssertEqual(dbTalkPage?.discussions?.count, 1, "Unexpected discussion count")
        
        if let firstDiscussion = dbTalkPage?.discussions?[0] as? TalkPageDiscussion {
            XCTAssertEqual(firstDiscussion.title, "Would you please help me expand the Puppy cat article?", "Unexpected discussion title")
            XCTAssertEqual(firstDiscussion.items?.count, 2, "Unexpected discussion items count")
            
            if let firstDiscussionItem = firstDiscussion.items?[0] as? TalkPageDiscussionItem {
                XCTAssertEqual(firstDiscussionItem.text, "Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last wee. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected discussion item text")
                XCTAssertEqual(firstDiscussionItem.depth, 0, "Unexpected discussion item depth")
                XCTAssertEqual(firstDiscussionItem.unalteredText, "<table><tr><td>Insert bonkers template here</td></tr></table> Hi Pixiu! Glad we were able to meet at the Bay Area Puppercat Edit-a-thon last wee. I noticed that the <a href=\'https://en.wikipedia.org/wiki/Puppy_cat\'>Puppy cat</a> could use some more information about ragdolls, do you think that this might be something you\'d be interested in contributing to? <a href=\'https://en.wikipedia.org/wiki/User:Fruzia\'>Fruzia</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Fruzia\'>talk</a>) 23:08. 20 March 2019 (UTC)", "Unexpected discussion item unalteredText")
            } else {
                XCTFail("Unexpected first discussion item type")
            }
            
            if let secondDiscussionItem = firstDiscussion.items?[1] as? TalkPageDiscussionItem {
                XCTAssertEqual(secondDiscussionItem.text, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected discussion item text")
                XCTAssertEqual(secondDiscussionItem.depth, 1, "Unexpected discussion item depth")
                XCTAssertEqual(secondDiscussionItem.unalteredText, "Hi Fruzia, thanks for reaching out! I\'ll go and take a look at the article and see what I can contribute with the resources I have at paw. <img src=\'https://upload.wikimedia.org/wikipedia/commons/c/c0/A_cat%27s_paw_2%2C_ubt.JPG\' /> <a href=\'https://en.wikipedia.org/wiki/User:Pixiu\'>Pixiu</a> (<a href=\'https://en.wikipedia.org/wiki/User_talk:Pixiu\'>talk</a>) 08:09. 21 March 2019 (UTC)", "Unexpected discussion item unalteredText")
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
    
    func testCreateWithDifferentNameOrLanguageAddsAllToDatabase() {
        
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        //create first network talk page
        guard let firstTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //add first db talk page
        var firstDbTalkPage: TalkPage?
        do {
            firstDbTalkPage = try tempDataStore.viewContext.wmf_createOrUpdateTalkPage(talkPage: firstTalkPage)
        } catch (let error) {
            XCTFail("Create Or Update Talk Page call failed: \(error)")
        }
        
        let firstKeyedUrlString = URL(string: urlString1)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(firstDbTalkPage?.key)
        XCTAssertEqual(firstDbTalkPage?.key, firstKeyedUrlString, "Unexpected key")
        
        //confirm one talk page exists in DB
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching saved talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 1, "Expected 1 talk page in DB")
        XCTAssertEqual(firstResults.first, firstDbTalkPage)
        
        //create second network talk page
        guard let secondTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString2) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //add second db talk page
        var secondDbTalkPage: TalkPage?
        do {
            secondDbTalkPage = try tempDataStore.viewContext.wmf_createOrUpdateTalkPage(talkPage: secondTalkPage)
        } catch (let error) {
            XCTFail("Create Or Update Talk Page call failed: \(error)")
        }
        
        let secondKeyedUrlString = URL(string: urlString2)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(secondDbTalkPage?.key)
        XCTAssertEqual(secondDbTalkPage?.key, secondKeyedUrlString, "Unexpected key")
        
        //confirm two talk pages exist in DB
        guard let secondResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching saved talk pages")
            return
        }
        
        XCTAssertEqual(secondResults.count, 2, "Expected 2 talk pages in DB")
        XCTAssertEqual(secondResults[0], firstDbTalkPage)
        XCTAssertEqual(secondResults[1], secondDbTalkPage)
        
        //create third network talk page
        guard let thirdTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString3) else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //add second db talk page
        var thirdDbTalkPage: TalkPage?
        do {
            thirdDbTalkPage = try tempDataStore.viewContext.wmf_createOrUpdateTalkPage(talkPage: thirdTalkPage)
        } catch (let error) {
            XCTFail("Create Or Update Talk Page call failed: \(error)")
        }
        
        let thirdKeyedUrlString = URL(string: urlString3)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(thirdDbTalkPage?.key)
        XCTAssertEqual(thirdDbTalkPage?.key, thirdKeyedUrlString, "Unexpected key")
        
        //confirm two talk pages exist in DB
        guard let thirdResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching saved talk pages")
            return
        }
        
        XCTAssertEqual(thirdResults.count, 3, "Expected 2 talk pages in DB")
        XCTAssertEqual(thirdResults[0], firstDbTalkPage)
        XCTAssertEqual(thirdResults[1], secondDbTalkPage)
        XCTAssertEqual(thirdResults[2], thirdDbTalkPage)
    }
    
    func testCreateWithSameKeyUpdatesDatabase() {
        
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        //add network talk page
        guard let talkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, talkPageString: "TalkPage") else {
            XCTFail("Failure stubbing out network talk page")
            return
        }
        
        //create db talk page
        var dbTalkPage: TalkPage?
        do {
            dbTalkPage = try tempDataStore.viewContext.wmf_createOrUpdateTalkPage(talkPage: talkPage)
        } catch (let error) {
            XCTFail("Create Or Update Talk Page call failed: \(error)")
        }
        
        //assert db talk page values
        let keyedUrlString = URL(string: urlString1)?.wmf_talkPageDatabaseKey
        XCTAssertNotNil(dbTalkPage?.key)
        XCTAssertEqual(dbTalkPage?.key, keyedUrlString, "Unexpected key")
        XCTAssertEqual(dbTalkPage?.revisionId, 0, "Unexpected revisionId")
        XCTAssertEqual(dbTalkPage?.name, "Pixiu", "Unexpected name")
        XCTAssertEqual(dbTalkPage?.discussions?.count, 1, "Unexpected discussion count")
        
        if let firstDiscussion = dbTalkPage?.discussions?[0] as? TalkPageDiscussion {
            XCTAssertEqual(firstDiscussion.title, "Would you please help me expand the Puppy cat article?", "Unexpected discussion title")
            XCTAssertEqual(firstDiscussion.items?.count, 2, "Unexpected discussion items count")
        }
        
        //confirm 1 discussion object in DB
         let discussionFetchRequest: NSFetchRequest<TalkPageDiscussion> = TalkPageDiscussion.fetchRequest()
        guard let discussionResults = try? tempDataStore.viewContext.fetch(discussionFetchRequest) else {
            XCTFail("Failure fetching discussions")
            return
        }
        
        XCTAssertEqual(discussionResults.count, 1, "Expected 1 discussion object in DB")
        
        //confirm 2 discussion item objects in DB
        let discussionItemFetchRequest: NSFetchRequest<TalkPageDiscussionItem> = TalkPageDiscussionItem.fetchRequest()
        guard let discussionItemResults = try? tempDataStore.viewContext.fetch(discussionItemFetchRequest) else {
            XCTFail("Failure fetching discussion items")
            return
        }
        
        XCTAssertEqual(discussionItemResults.count, 2, "Expected 2 discussion item objects in DB")
        
        //add updated network talk page
        guard let updatedTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, talkPageString: "TalkPageUpdated") else {
            XCTFail("Failure stubbing out updated network talk page")
            return
        }
        
        //update db talk page
        var updatedDBTalkPage: TalkPage?
        do {
            updatedDBTalkPage = try tempDataStore.viewContext.wmf_createOrUpdateTalkPage(talkPage: updatedTalkPage)
        } catch (let error) {
            XCTFail("Create Or Update Talk Page call failed: \(error)")
        }
        
        //assert updated db talk page values
        XCTAssertNotNil(updatedDBTalkPage?.key)
        XCTAssertEqual(updatedDBTalkPage?.key, keyedUrlString, "Unexpected key")
        XCTAssertEqual(updatedDBTalkPage?.revisionId, 1, "Unexpected revisionId")
        XCTAssertEqual(updatedDBTalkPage?.name, "Pixiu", "Unexpected name")
        XCTAssertEqual(updatedDBTalkPage?.discussions?.count, 1, "Unexpected discussion count")
        
        if let firstDiscussion = dbTalkPage?.discussions?[0] as? TalkPageDiscussion {
            XCTAssertEqual(firstDiscussion.title, "Would you please help me expand the Puppy cat article?", "Unexpected discussion title")
            XCTAssertEqual(firstDiscussion.items?.count, 3, "Unexpected discussion items count")
        }
        
        //confirm 1 discussion object in DB
        let updatedDiscussionFetchRequest: NSFetchRequest<TalkPageDiscussion> = TalkPageDiscussion.fetchRequest()
        guard let updatedDiscussionResults = try? tempDataStore.viewContext.fetch(updatedDiscussionFetchRequest) else {
            XCTFail("Failure fetching discussions")
            return
        }
        
        XCTAssertEqual(updatedDiscussionResults.count, 1, "Expected 1 discussion object in DB")
        
        //confirm 2 discussion item objects in DB
        let updatedDiscussionItemFetchRequest: NSFetchRequest<TalkPageDiscussionItem> = TalkPageDiscussionItem.fetchRequest()
        guard let updatedDiscussionItemResults = try? tempDataStore.viewContext.fetch(updatedDiscussionItemFetchRequest) else {
            XCTFail("Failure fetching discussion items")
            return
        }
        
        XCTAssertEqual(updatedDiscussionItemResults.count, 3, "Expected 2 discussion item objects in DB")
        
    }
}
