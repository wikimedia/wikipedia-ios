import XCTest
import CoreData
@testable import Wikipedia

class TalkPageManualPerformanceTests: XCTestCase {
    
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

    func testPerformanceLargeToLargeUpdateTalkPages() {
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        guard let largeJson = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.largeForPerformance.fileName, ofType: "json"),
            let largeUpdatedJson = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.largeUpdatedForPerformance.fileName, ofType: "json"),
            let networkTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: largeJson, revisionId: 1),
            let updatedNetworkTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: largeUpdatedJson, revisionId: 1) else {
            XCTFail("Failure stubbing out network talk pages")
            return
        }
        
        var i = 0
        measure {
            i += 1
            
            //create db talk page
            guard let talkPage = moc.createTalkPage(with: networkTalkPage) else {
                XCTFail("Failure to create db talk page")
                return
            }
            
            //update local copy
            guard let _ = moc.updateTalkPage(talkPage, with: updatedNetworkTalkPage) else {
                XCTFail("Failure updating existing local talk page")
                return
            }
        }
        
    }
    
    func testPerformanceSmallToLargeUpdateTalkPages() {
        //confirm no talk pages in DB
        let fetchRequest: NSFetchRequest<TalkPage> = TalkPage.fetchRequest()
        
        guard let firstResults = try? tempDataStore.viewContext.fetch(fetchRequest) else {
            XCTFail("Failure fetching initial talk pages")
            return
        }
        
        XCTAssertEqual(firstResults.count, 0, "Expected zero existing talk pages at first")
        
        guard let smallJson = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.smallForPerformance.fileName, ofType: "json"),
            let largeUpdatedJson = wmf_bundle().wmf_data(fromContentsOfFile: TalkPageTestHelpers.TalkPageJSONType.largeUpdatedForPerformance.fileName, ofType: "json"),
            let networkTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: smallJson, revisionId: 1),
            let updatedNetworkTalkPage = TalkPageTestHelpers.networkTalkPage(for: urlString1, data: largeUpdatedJson, revisionId: 1) else {
                XCTFail("Failure stubbing out network talk pages")
                return
        }
        
        var i = 0
        measure {
            i += 1
            
            //create db talk page
            guard let talkPage = moc.createTalkPage(with: networkTalkPage) else {
                XCTFail("Failure to create db talk page")
                return
            }
            
            //update local copy
            guard let _ = moc.updateTalkPage(talkPage, with: updatedNetworkTalkPage) else {
                XCTFail("Failure updating existing local talk page")
                return
            }
        }
        
    }

}
