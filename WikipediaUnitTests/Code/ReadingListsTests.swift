import XCTest

class ReadingListsTests: XCTestCase {
    
    var dataStore: MWKDataStore!
    
    override func setUp(completion: @escaping (Error?) -> Void) {
        MWKDataStore.createTemporaryDataStore(completion: { dataStore in
            self.dataStore = dataStore
            completion(nil)
        })
    }
    
    override func tearDown() {
        super.tearDown()
        dataStore.removeFolderAtBasePath()
    }
    
    func testListsWithTheSameName() {
        let originalName = "pebbles"
        let casedName = "pEbBLes"
        let diacriticName = "pEbBLés"
        do {
            let list = try dataStore.readingListsController.createReadingList(named: originalName, description: "Foo")
            XCTAssert(list.name == originalName)
        } catch let error {
            XCTAssert(false, "Should be able to create \(originalName) reading list: \(error)")
        }
        do {
            _ = try dataStore.readingListsController.createReadingList(named: casedName, description: "Foo")
            XCTAssert(true, "Should be able to create list with same title and different case")
        } catch let error {
            XCTAssert(false, "Should not throw an error: \(error) when creating a list with the same title and different case")
        }
        
        do {
            let list = try dataStore.readingListsController.createReadingList(named: diacriticName, description: "Foo")
            XCTAssert(list.name == diacriticName)
        } catch let error {
            XCTAssert(false, "Should be able to create \(diacriticName) reading list: \(error)")
        }
    }
    
    func testDeletingExistingReadingLists() {
        let readingListNames = ["foo", "bar"]
        var readingLists: [ReadingList] = []

        do {
            readingLists.append(try dataStore.readingListsController.createReadingList(named: readingListNames[0], description: "Foo"))
        } catch let error {
            XCTAssert(false, "Should be able to create \(readingListNames[0]) reading list: \(error)")
        }
        
        do {
            readingLists.append(try dataStore.readingListsController.createReadingList(named: readingListNames[1], description: "Foo"))
        } catch let error {
            XCTAssert(false, "Should be able to create \(readingListNames[1]) reading list: \(error)")
        }
        
        do {
            try dataStore.readingListsController.delete(readingLists: readingLists)
        } catch let error {
            XCTAssert(false, "Should be able to delete \(readingListNames) reading lists: \(error)")
        }
    }
    
    func testDeletingNonexistentReadingLists() {
        let readingListNames = ["foo", "bar"]
        var readingLists: [ReadingList] = []
        
        do {
            readingLists.append(try dataStore.readingListsController.createReadingList(named: readingListNames[0], description: "Foo"))
        } catch let error {
            XCTAssert(false, "Should be able to create \(readingListNames[0]) reading list: \(error)")
        }
        
        do {
            try dataStore.readingListsController.delete(readingLists: readingLists)
        } catch let error {
            XCTAssert(false, "Should attempt to delete \(readingListNames) reading lists: \(error)")
        }
    }
    
    func testCreatingReadingListWithArticles() {
        let readingListName = "foo"
        let articleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Bar")!]
        let articles = articleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let articleKeys = articles.compactMap { (article) -> String? in
            return article.key
        }
        
        do {
            let readingList = try dataStore.readingListsController.createReadingList(named: readingListName, description: "Foo", with: articles)
            XCTAssert(readingList.articleKeys.wmf_containsObjectsInAnyOrderAndMatchesCount(articleKeys))

        } catch let error {
            XCTAssert(false, "Should be able to add articles to \(readingListName) reading list: \(error)")
        }
        
    }
    
    func testAddingArticlesToExistingReadingList() {
        let readingListName = "foo"
        let articleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Bar")!]
        let otherArticleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Bar")!, URL(string: "//en.wikipedia.org/wiki/Baz")!]
        
        let articles = articleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let otherArticles = otherArticleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let otherArticleKeys = otherArticles.compactMap { (article) -> String? in
            return article.key
        }
        
        do {
            let readingList = try dataStore.readingListsController.createReadingList(named: readingListName, description: "Foo", with: articles)
            
            do {
                try dataStore.readingListsController.add(articles: otherArticles, to: readingList)
                XCTAssert(readingList.articleKeys.wmf_containsObjectsInAnyOrderAndMatchesCount(otherArticleKeys))
            } catch let error {
                XCTAssert(false, "Should be able to : \(error)")
            }
            
        } catch let error {
            XCTAssert(false, "Should be able to add articles to \(readingListName) reading list: \(error)")
        }
        
    }
    
    func testAddingDuplicateArticlesToExistingReadingList() {
        let readingListName = "foo"
        let articleURLs = [URL(string: "//en.wikipedia.org/wiki/Foo")!, URL(string: "//en.wikipedia.org/wiki/Foo")!]
        
        let articles = articleURLs.compactMap { (articleURL) -> WMFArticle? in
            return dataStore.fetchOrCreateArticle(with: articleURL)
        }
        
        let articleKeys = articles.compactMap { (article) -> String? in
            return article.key
        }
        
        do {
            let readingList = try dataStore.readingListsController.createReadingList(named: readingListName, description: "Foo", with: articles)
            let existingArticleKeys = readingList.articleKeys
            XCTAssert(existingArticleKeys.wmf_containsObjectsInAnyOrder(articleKeys) && existingArticleKeys.count == 1)
        } catch let error {
            XCTAssert(false, "Should be able to add articles to \(readingListName) reading list: \(error)")
        }
    }
}

extension Array where Element: Hashable {
    func wmf_containsObjectsInAnyOrderAndMatchesCount(_ other: [Element]) -> Bool {
        return wmf_containsObjectsInAnyOrder(other) && self.count == other.count
    }
    
    func wmf_containsObjectsInAnyOrder(_ other: [Element]) -> Bool {
        let selfSet = Set(self)
        let otherSet = Set(other)
        return otherSet.isSubset(of: selfSet)
    }
}

