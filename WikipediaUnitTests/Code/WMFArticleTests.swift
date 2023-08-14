import XCTest
@testable import WMF

class WMFArticleTests: XCTestCase {
    
    var dataStore: MWKDataStore!
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }
    
    var a: WMFArticle!
    var b: WMFArticle!
    
    override func setUp() {
        a = WMFArticle(context: moc)
        b = WMFArticle(context: moc)
    }
    
    var moc: NSManagedObjectContext {
        return dataStore.viewContext
    }

    func testMergeReadingLists() {
        let c = ReadingList(context: moc)
        let d = ReadingList(context: moc)
        let e = ReadingList(context: moc)
        a.addReadingListsObject(c)
        b.addReadingListsObject(d)
        b.addReadingListsObject(e)
        a.merge(b)
        XCTAssert(a.readingLists == [c, d, e], "Merging should combine reading lists")
    }
    
    func testMergeEmptyReadingLists() {
        let c = ReadingList(context: moc)
        a.addReadingListsObject(c)
        a.merge(b)
        XCTAssert(a.readingLists == [c], "Merging should combine reading lists")
    }
    
    func testMergeIsExcludedFromFeed() {
        a.isExcludedFromFeed = false
        b.isExcludedFromFeed = true
        a.merge(b)
        XCTAssert(a.isExcludedFromFeed, "Merging should preserve isExcludedFromFeed")
    }

    func testMergeExistingIsExcludedFromFeed() {
        a.isExcludedFromFeed = true
        b.isExcludedFromFeed = false
        a.merge(b)
        XCTAssert(a.isExcludedFromFeed, "Merging should preserve existing isExcludedFromFeed")
    }
    
    
    func testMergeViewedDates() {
        a.viewedDate = Date(timeIntervalSince1970: 1)
        b.viewedDate = Date(timeIntervalSince1970: -1)
        a.viewedFragment = "a"
        b.viewedFragment = "b"
        a.merge(b)
        guard let viewedDate = a.viewedDate else {
            XCTAssert(false, "Viewed date should be set")
            return
        }
        XCTAssert(viewedDate.timeIntervalSince1970 > 0, "Merging should take the later date")
        XCTAssert(a.viewedFragment == "a", "Merging should take the later viewed fragment")
        
        a.viewedDate = Date(timeIntervalSince1970: -1)
        b.viewedDate = Date(timeIntervalSince1970: 1)
        a.viewedFragment = "a"
        b.viewedFragment = "b"
        a.merge(b)
        guard let bViewedDate = a.viewedDate else {
            XCTAssert(false, "Viewed date should be set")
            return
        }
        XCTAssert(bViewedDate.timeIntervalSince1970 > 0, "Merging should take the later date")
        XCTAssert(a.viewedFragment == "b", "Merging should take the later viewed fragment")
    }
    
    func testMergeSavedDate() {
        a.savedDate = Date(timeIntervalSince1970: 1)
        b.savedDate = Date(timeIntervalSince1970: -1)
        a.merge(b)
        guard let savedDate = a.savedDate else {
            XCTAssert(false, "Saved date should be set")
            return
        }
        XCTAssert(savedDate.timeIntervalSince1970 > 0, "Merging should take the later date")
    }
    
    func testMergeNilSavedDate() {
        a.savedDate = Date(timeIntervalSince1970: 1)
        b.savedDate = nil
        a.merge(b)
        XCTAssert(a.savedDate != nil, "Saved date should be set")
    }
    
    func testMergeNonNilSavedDate() {
        a.savedDate = nil
        b.savedDate = Date(timeIntervalSince1970: 1)
        a.merge(b)
        XCTAssert(a.savedDate != nil, "Saved date should be set")
    }
    
    func testMergeNonNilViewedDate() {
        a.viewedDate = nil
        b.viewedDate = Date(timeIntervalSince1970: 1)
        a.merge(b)
        XCTAssert(a.viewedDate != nil, "Viewed date should be set")
    }
    
    func testArticleTemporaryCacheKey() {
        // Ensure WMFArticleTemporaryCacheKey works as expected as a key into the WMFArticle temporary cache
        let articleCache = NSCache<WMFInMemoryURLKey, NSString>()
        
        let hantString: NSString = "ZH article with hant variant"
        let hantKey = WMFInMemoryURLKey(databaseKey:"ZH article", languageVariantCode:"hant")
        articleCache.setObject(hantString, forKey:hantKey)
        
        let hansString: NSString = "ZH article with hans variant"
        let hansKey = WMFInMemoryURLKey(databaseKey:"ZH article", languageVariantCode:"hans")
        articleCache.setObject(hansString, forKey:hansKey)
        
        let noVariantString: NSString = "ZH article with no variant"
        let noVariantKey = WMFInMemoryURLKey(databaseKey:"ZH article", languageVariantCode:nil)
        articleCache.setObject(noVariantString, forKey:noVariantKey)
        
        let newHantKey = WMFInMemoryURLKey(databaseKey:"ZH article", languageVariantCode:"hant")
        var hantValue = articleCache.object(forKey:newHantKey)
        XCTAssertEqual(hantValue, hantString)
        
        let newHansKey = WMFInMemoryURLKey(databaseKey:"ZH article", languageVariantCode:"hans")
        var hansValue = articleCache.object(forKey:newHansKey)
        XCTAssertEqual(hansValue, hansString)
        
        let newNoVariantKey = WMFInMemoryURLKey(databaseKey:"ZH article", languageVariantCode:nil)
        var noVariantValue = articleCache.object(forKey:newNoVariantKey)
        XCTAssertEqual(noVariantValue, noVariantString)
        
        hansValue = articleCache.object(forKey:hansKey)
        XCTAssertEqual(hansValue, hansString)
        
        hantValue = articleCache.object(forKey:hantKey)
        XCTAssertEqual(hantValue, hantString)
        
        noVariantValue = articleCache.object(forKey:noVariantKey)
        XCTAssertEqual(noVariantValue, noVariantString)
    }
}
