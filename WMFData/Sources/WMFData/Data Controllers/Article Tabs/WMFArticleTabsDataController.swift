import Foundation
import UIKit
import CoreData

public class WMFArticleTabsDataController {
    
    // MARK: - Nested Public Types
    
    public enum CustomError: Error {
        case missingTab
        case missingSelf
        case cannotDeleteLastTab
        case missingPage
        case unexpectedType
        case missingTabIdentifier
    }
    
    public struct WMFArticle {
        let title: String
        let project: WMFProject
    }
    
    public struct WMFArticleTab {
        let identifier: UUID
        let articles: [WMFArticle]
    }
    
    // MARK: - Properties
    
    public let coreDataStore: WMFCoreDataStore
    private let userDefaultsStore: WMFKeyValueStore?
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    
    // MARK: - Lifecycle
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, userDefaultsStore: WMFKeyValueStore? = WMFDataEnvironment.current.userDefaultsStore, developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared) throws {

        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
        self.userDefaultsStore = userDefaultsStore
        self.developerSettingsDataController = developerSettingsDataController
    }
    
    // MARK: Entry point

   public var shouldShowArticleTabs: Bool {
        get {
            return (try? userDefaultsStore?.load(key: WMFUserDefaultsKey.developerSettingsArticleTab.rawValue)) ?? false
        } set {
            try? userDefaultsStore?.save(key: WMFUserDefaultsKey.developerSettingsArticleTab.rawValue, value: newValue)
        }
    }
    
    // MARK: - Tabs Manipulation Methods
    
    public func tabsCount() async throws -> Int {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        let result: Int = try await backgroundContext.perform {
            let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
            return try backgroundContext.count(for: fetchRequest)
        }
        
        return result
    }

    public func createArticleTab(initialArticle: WMFArticle?, setAsCurrent: Bool = false) async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { throw CustomError.missingSelf }
            
            // If we need to insert an initial article, create or fetch existing CDPage of article.
            var page: CDPage?
            if let initialArticle {
                page = try pageForArticle(initialArticle, moc: backgroundContext)
            }
            
            // Create CDArticleTab
            let newArticleTab = try self.coreDataStore.create(entityType: CDArticleTab.self, in: backgroundContext)
            newArticleTab.timestamp = Date()
            newArticleTab.isCurrent = setAsCurrent
            newArticleTab.identifier = UUID()
            
            // Create CDArticleTabItem and add to newArticleTab
            if let page {
                let articleTabItem = try newArticleTabItem(page: page, moc: backgroundContext)
                newArticleTab.items = NSOrderedSet(array: [articleTabItem])
            }
            
            // Save DB
            try coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func deleteArticleTab(identifier: UUID) async throws {
        
        let tabsCount = try await tabsCount()
        
        if tabsCount <= 1 {
            throw CustomError.cannotDeleteLastTab
        }
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { throw CustomError.missingSelf }
            
            let predicate = NSPredicate(format: "identifier == %@", argumentArray: [identifier])
            
            guard let articleTab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: backgroundContext)?.first else {
                throw CustomError.missingTab
            }
            
            if let items = articleTab.items {
                for item in items {
                    guard let articleTabItem = item as? CDArticleTabItem else {
                        throw CustomError.unexpectedType
                    }
                    
                    articleTabItem.tab = nil
                    backgroundContext.delete(articleTabItem)
                }
            }
            
            backgroundContext.delete(articleTab)
            
            try coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func appendArticle(_ article: WMFArticle, toTabIdentifier identifier: UUID) async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { throw CustomError.missingSelf }
            
            let tabPredicate = NSPredicate(format: "identifier == %@", argumentArray: [identifier])
            
            guard let tab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: tabPredicate, fetchLimit: 1, in: backgroundContext)?.first else {
                throw CustomError.missingTab
            }
            
            let page = try pageForArticle(article, moc: backgroundContext)
            
            let articleTabItem = try newArticleTabItem(page: page, moc: backgroundContext)
            
            if let currentItems = tab.items as? NSMutableOrderedSet {
                currentItems.add(articleTabItem)
            } else {
                tab.items = NSOrderedSet(array: [articleTabItem])
            }
            
            try coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func removeLastArticleFromTab(tabIdentifier: UUID) async throws {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        try await backgroundContext.perform { [weak self] in
            
            guard let self else { throw CustomError.missingSelf }
            
            let predicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
            
            guard let tab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: backgroundContext)?.first else {
                throw CustomError.missingTab
            }
            
            guard let items = tab.items as? NSMutableOrderedSet, items.count > 0 else {
                throw CustomError.missingPage
            }
            
            // Get last item and delete it
            guard let lastItem = items.lastObject as? CDArticleTabItem else {
                throw CustomError.unexpectedType
            }
            
            items.removeObject(at: items.count - 1)
            lastItem.tab = nil
            backgroundContext.delete(lastItem)
            
            try coreDataStore.saveIfNeeded(moc: backgroundContext)
        }
    }
    
    public func fetchAllArticleTabs() async throws -> [WMFArticleTab] {
        
        let backgroundContext = try coreDataStore.newBackgroundContext
        
        let result: [WMFArticleTab] = try await backgroundContext.perform { [weak self] in
            
            guard let self else { throw CustomError.missingSelf }
            
            guard let cdArticleTabs = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: nil, fetchLimit: nil, in: backgroundContext) else {
                throw CustomError.missingTab
            }
            
            var articleTabs: [WMFArticleTab] = []
            
            for cdTab in cdArticleTabs {
                guard let identifier = cdTab.identifier else {
                    throw CustomError.missingTabIdentifier
                }
                
                var articles: [WMFArticle] = []
                
                guard let items = cdTab.items else {
                    continue
                }
                
                for item in items {
                    guard let articleTabItem = item as? CDArticleTabItem,
                          let page = articleTabItem.page,
                          let title = page.title,
                          let projectID = page.projectID,
                          let project = WMFProject(coreDataIdentifier: projectID) else {
                        throw CustomError.unexpectedType
                    }
                    
                    let article = WMFArticle(title: title, project: project)
                    articles.append(article)
                }
                
                let articleTab = WMFArticleTab(identifier: identifier, articles: articles)
                articleTabs.append(articleTab)
            }
            
            return articleTabs
        }
        
        return result
    }
    
    private func pageForArticle(_ article: WMFArticle, moc: NSManagedObjectContext) throws -> CDPage {

        let coreDataTitle = article.title.normalizedForCoreData
        let pagePredicate = NSPredicate(format: "projectID == %@ && namespaceID == %@ && title == %@", argumentArray: [article.project.coreDataIdentifier, 0, coreDataTitle])
        
        let page = try self.coreDataStore.fetchOrCreate(entityType: CDPage.self, predicate: pagePredicate, in: moc)
        
        guard let page else {
            throw CustomError.missingPage
        }
        
        page.title = coreDataTitle
        page.namespaceID = 0
        page.projectID = article.project.coreDataIdentifier
        if page.timestamp == nil {
            page.timestamp = Date()
        }
        
        return page
    }
    
    private func newArticleTabItem(page: CDPage, moc: NSManagedObjectContext) throws -> CDArticleTabItem {

        let newArticleTabItem = try self.coreDataStore.create(entityType: CDArticleTabItem.self, in: moc)
        newArticleTabItem.page = page
        return newArticleTabItem
    }
}
