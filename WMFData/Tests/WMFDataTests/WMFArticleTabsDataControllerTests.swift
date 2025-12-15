import XCTest
@testable import WMFData
@testable import WMFDataMocks

final class WMFArticleTabsDataControllerTests: XCTestCase {
    
    enum TestsError: Error {
        case missingStore
        case missingDataController
    }
    
    var store: WMFCoreDataStore?
    var dataController: WMFArticleTabsDataController?
    
    lazy var enProject: WMFProject = {
        let language = WMFLanguage(languageCode: "en", languageVariantCode: nil)
        return .wikipedia(language)
    }()
    
    override func setUp() async throws {
        let temporaryDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = try await WMFCoreDataStore(appContainerURL: temporaryDirectory)
        self.store = store
        
        WMFDataEnvironment.current.appData = WMFAppData(appLanguages: [WMFLanguage(languageCode: "en", languageVariantCode: nil)])
        
        self.dataController = WMFArticleTabsDataController(coreDataStore: store)
        
        try await super.setUp()
    }
    
    func testTabsCount() async throws {
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // Initially should be 0
        var count = try await dataController.tabsCount()
        XCTAssertEqual(count, 0)
        
        // Create a tab
        _ = try await dataController.createArticleTab(initialArticle: nil)
        
        // Should now be 1
        count = try await dataController.tabsCount()
        XCTAssertEqual(count, 1)
    }
    
    func testCreateArticleTab() async throws {
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // Create a tab with an initial article
        let article = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Cat",
            description: "Small domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Cat")
        )
        
        let identifier = try await dataController.createArticleTab(initialArticle: article)
        
        // Verify the tab was created with the correct article
        try await store.viewContext.perform {
            let predicate = NSPredicate(format: "identifier == %@", identifier.tabIdentifier as CVarArg)
            guard let tab = try store.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch created tab")
                return
            }
            
            XCTAssertNotNil(tab.identifier)
            XCTAssertEqual(tab.identifier, identifier.tabIdentifier)
            XCTAssertNotNil(tab.items)
            XCTAssertEqual(tab.items?.count, 1)
            
            guard let item = tab.items?.firstObject as? CDArticleTabItem,
                  let page = item.page else {
                XCTFail("Failed to get article tab item or page")
                return
            }
            
            XCTAssertEqual(page.title, "Cat")
            XCTAssertEqual(page.projectID, self.enProject.id)
        }
    }
    
    func testDeleteArticleTab() async throws {
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // Create two tabs
        let firstArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Cat",
            description: "Small domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Cat")
        )
        let identifier1 = try await dataController.createArticleTab(initialArticle: firstArticle)
        
        let secondArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Dog",
            description: "Domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Dog")
        )
        let identifier2 = try await dataController.createArticleTab(initialArticle: secondArticle)
        
        // Verify initial count
        var count = try await dataController.tabsCount()
        XCTAssertEqual(count, 2)
        
        // Delete one tab
        try await dataController.deleteArticleTab(identifier: identifier1.tabIdentifier)
        
        // Verify count decreased
        count = try await dataController.tabsCount()
        XCTAssertEqual(count, 1)
        
        // Verify the correct tab was deleted
        try await store.viewContext.perform {
            let predicate = NSPredicate(format: "identifier == %@", identifier1.tabIdentifier as CVarArg)
            let deletedTab = try store.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: store.viewContext)?.first
            XCTAssertNil(deletedTab, "Tab should be deleted")
            
            let remainingPredicate = NSPredicate(format: "identifier == %@", identifier2.tabIdentifier as CVarArg)
            let remainingTab = try store.fetch(entityType: CDArticleTab.self, predicate: remainingPredicate, fetchLimit: 1, in: store.viewContext)?.first
            XCTAssertNotNil(remainingTab, "Other tab should still exist")
            
            // Verify the remaining tab still has its article
            guard let item = remainingTab?.items?.firstObject as? CDArticleTabItem,
                  let page = item.page else {
                XCTFail("Failed to get article tab item or page")
                return
            }
            
            XCTAssertEqual(page.title, "Dog")
            XCTAssertEqual(page.projectID, self.enProject.id)
        }
    }
    
    func testAppendArticle() async throws {
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // Create a tab with an initial article
        let initialArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Cat",
            description: "Small domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Cat")
        )
        let identifier = try await dataController.createArticleTab(initialArticle: initialArticle)
        
        // Append another article
        let newArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Dog",
            description: "Domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Dog")
        )
        _ = try await dataController.appendArticle(newArticle, toTabIdentifier: identifier.tabIdentifier)
        
        // Verify both articles are in the tab
        try await store.viewContext.perform {
            let predicate = NSPredicate(format: "identifier == %@", identifier.tabIdentifier as CVarArg)
            guard let tab = try store.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch tab")
                return
            }
            
            XCTAssertEqual(tab.items?.count, 2)
            
            guard let items = tab.items?.array as? [CDArticleTabItem] else {
                XCTFail("Failed to get items array")
                return
            }
            
            XCTAssertEqual(items[0].page?.title, "Cat")
            XCTAssertEqual(items[1].page?.title, "Dog")
        }
    }
    
    func testIsCurrentTab() async throws {
        guard let store else {
            throw TestsError.missingStore
        }
        
        guard let dataController else {
            throw TestsError.missingDataController
        }
        
        // Create first tab and set it as current
        let firstArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Cat",
            description: "Small domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Cat")
        )
        let identifier1 = try await dataController.createArticleTab(initialArticle: firstArticle, setAsCurrent: true)
        
        // Verify first tab is current
        try await store.viewContext.perform {
            let predicate = NSPredicate(format: "identifier == %@", identifier1.tabIdentifier as CVarArg)
            guard let tab1 = try store.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch first tab")
                return
            }
            XCTAssertTrue(tab1.isCurrent, "First tab should be current")
        }
        
        // Create second tab without setting it as current
        let secondArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Dog",
            description: "Domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Dog")
        )
        let identifier2 = try await dataController.createArticleTab(initialArticle: secondArticle, setAsCurrent: false)
        
        // Verify first tab is still current and second tab is not
        try await store.viewContext.perform {
            let predicate1 = NSPredicate(format: "identifier == %@", identifier1.tabIdentifier as CVarArg)
            guard let tab1 = try store.fetch(entityType: CDArticleTab.self, predicate: predicate1, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch first tab")
                return
            }
            XCTAssertTrue(tab1.isCurrent, "First tab should still be current")
            
            let predicate2 = NSPredicate(format: "identifier == %@", identifier2.tabIdentifier as CVarArg)
            guard let tab2 = try store.fetch(entityType: CDArticleTab.self, predicate: predicate2, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch second tab")
                return
            }
            XCTAssertFalse(tab2.isCurrent, "Second tab should not be current")
        }
        
        // Create third tab and set it as current
        let thirdArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Bird",
            description: "Warm-blooded vertebrate animal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Bird")
        )
        let identifier3 = try await dataController.createArticleTab(initialArticle: thirdArticle, setAsCurrent: true)
        
        // Verify third tab is current and others are not
        try await store.viewContext.perform {
            let predicate1 = NSPredicate(format: "identifier == %@", identifier1.tabIdentifier as CVarArg)
            guard let tab1 = try store.fetch(entityType: CDArticleTab.self, predicate: predicate1, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch first tab")
                return
            }
            XCTAssertFalse(tab1.isCurrent, "First tab should no longer be current")
            
            let predicate2 = NSPredicate(format: "identifier == %@", identifier2.tabIdentifier as CVarArg)
            guard let tab2 = try store.fetch(entityType: CDArticleTab.self, predicate: predicate2, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch second tab")
                return
            }
            XCTAssertFalse(tab2.isCurrent, "Second tab should still not be current")
            
            let predicate3 = NSPredicate(format: "identifier == %@", identifier3.tabIdentifier as CVarArg)
            guard let tab3 = try store.fetch(entityType: CDArticleTab.self, predicate: predicate3, fetchLimit: 1, in: store.viewContext)?.first else {
                XCTFail("Failed to fetch third tab")
                return
            }
            XCTAssertTrue(tab3.isCurrent, "Third tab should be current")
        }
    }
    
    func testFetchAllArticleTabs() async throws {
        guard let store else {
            throw TestsError.missingStore
        }
        
        // Create and inject the mock controller
        let dataController = WMFArticleTabsDataController(
            coreDataStore: store
        )
        
        // Create two tabs with articles
        let firstArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Cat",
            description: "Small domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Cat")
        )
        let identifier1 = try await dataController.createArticleTab(initialArticle: firstArticle, setAsCurrent: true)
        
        let secondArticle = WMFArticleTabsDataController.WMFArticle(
            identifier: nil,
            title: "Dog",
            description: "Domesticated carnivorous mammal",
            project: enProject,
            articleURL: URL(string: "https://en.wikipedia.org/wiki/Dog")
        )
        let identifier2 = try await dataController.createArticleTab(initialArticle: secondArticle, setAsCurrent: false)
        
        // Fetch all tabs
        let tabs = try await dataController.fetchAllArticleTabs()
        
        // Verify the results
        XCTAssertEqual(tabs.count, 2, "Should fetch both tabs")
        
        // Verify first tab
        guard let firstTab = tabs.first(where: { $0.identifier == identifier1.tabIdentifier }) else {
            XCTFail("First tab not found")
            return
        }
        
        
        XCTAssertEqual(firstTab.articles.count, 1, "First tab should have one article")
        XCTAssertEqual(firstTab.articles[0].title, "Cat")
        
        // Verify second tab
        guard let secondTab = tabs.first(where: { $0.identifier == identifier2.tabIdentifier }) else {
            XCTFail("Second tab not found")
            return
        }
        XCTAssertEqual(secondTab.articles.count, 1, "Second tab should have one article")
        XCTAssertEqual(secondTab.articles[0].title, "Dog")
    }
}
