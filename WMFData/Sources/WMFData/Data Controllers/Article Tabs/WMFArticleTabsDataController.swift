import Foundation
import UIKit
import CoreData

public protocol WMFArticleTabsDataControlling {
    func tabsCount() async throws -> Int
    func createArticleTab(initialArticle: WMFArticleTabsDataController.WMFArticle?, setAsCurrent: Bool) async throws -> UUID
    func deleteArticleTab(identifier: UUID) async throws
    func appendArticle(_ article: WMFArticleTabsDataController.WMFArticle, toTabIdentifier identifier: UUID?) async throws
    func removeLastArticleFromTab(tabIdentifier: UUID) async throws
    func currentTabIdentifier() async throws -> UUID
    func fetchAllArticleTabs() async throws -> [WMFArticleTabsDataController.WMFArticleTab]
}

public class WMFArticleTabsDataController: WMFArticleTabsDataControlling {
    
    // MARK: - Nested Public Types
    
    public enum CustomError: Error {
        case missingTab
        case missingSelf
        case cannotDeleteLastTab
        case missingPage
        case unexpectedType
        case missingTabIdentifier
        case missingTimestamp
    }
    
    public struct WMFArticle {
        public let title: String
        public let description: String?
        public let summary: String?
        public let imageURL: URL?
        let project: WMFProject
        
        public init(title: String, description: String? = nil, summary: String? = nil, imageURL: URL? = nil, project: WMFProject) {
            self.title = title
            self.description = description
            self.summary = summary
            self.imageURL = imageURL
            self.project = project
        }
    }
    
    public struct WMFArticleTab {
        public let identifier: UUID
        public let timestamp: Date
        public let isCurrent: Bool
        public let articles: [WMFArticle]
        
        public init(identifier: UUID, timestamp: Date, isCurrent: Bool, articles: [WMFArticle]) {
            self.identifier = identifier
            self.timestamp = timestamp
            self.isCurrent = isCurrent
            self.articles = articles
        }
    }
    
    // MARK: - Properties
    
    public let coreDataStore: WMFCoreDataStore
    private let developerSettingsDataController: WMFDeveloperSettingsDataControlling
    private let articleSummaryDataController: WMFArticleSummaryDataControlling
    
    // MARK: - Lifecycle
    
    public init(coreDataStore: WMFCoreDataStore? = WMFDataEnvironment.current.coreDataStore, 
                developerSettingsDataController: WMFDeveloperSettingsDataControlling = WMFDeveloperSettingsDataController.shared,
                articleSummaryDataController: WMFArticleSummaryDataControlling = WMFArticleSummaryDataController()) throws {
        guard let coreDataStore else {
            throw WMFDataControllerError.coreDataStoreUnavailable
        }
        self.coreDataStore = coreDataStore
        self.developerSettingsDataController = developerSettingsDataController
        self.articleSummaryDataController = articleSummaryDataController
    }
    
    // MARK: Entry point

    public var shouldShowArticleTabs: Bool {
        return developerSettingsDataController.enableArticleTabs
    }
    
    // MARK: - Tabs Manipulation Methods
    
    public func tabsCount() async throws -> Int {
        let moc = try coreDataStore.newBackgroundContext
        return try await moc.perform {
            let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
            return try moc.count(for: fetchRequest)
        }
    }

    public func createArticleTab(initialArticle: WMFArticle?, setAsCurrent: Bool = false) async throws -> UUID {
        let moc = try coreDataStore.newBackgroundContext
        return try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            // If we need to insert an initial article, create or fetch existing CDPage of article.
            var page: CDPage?
            if let initialArticle {
                page = try self.pageForArticle(initialArticle, moc: moc)
            }
            
            // If setting as current, first set all other tabs to not current
            if setAsCurrent {
                let predicate = NSPredicate(format: "isCurrent == YES")
                let currentTab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first
                currentTab?.isCurrent = false
            }
            
            // Create CDArticleTab
            let newArticleTab = try self.coreDataStore.create(entityType: CDArticleTab.self, in: moc)
            newArticleTab.timestamp = Date()
            newArticleTab.isCurrent = setAsCurrent
            let identifier = UUID()
            newArticleTab.identifier = identifier
            
            // Create CDArticleTabItem and add to newArticleTab
            if let page {
                let articleTabItem = try self.newArticleTabItem(page: page, moc: moc)
                newArticleTab.items = NSOrderedSet(array: [articleTabItem])
            }
            
            try self.coreDataStore.saveIfNeeded(moc: moc)
            
            return identifier
        }
    }
    
    public func deleteArticleTab(identifier: UUID) async throws {
        let moc = try coreDataStore.newBackgroundContext
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }

            try self.deleteArticleTab(identifier: identifier, moc: moc)
            
            try self.coreDataStore.saveIfNeeded(moc: moc)
        }
    }
    
    public func appendArticle(_ article: WMFArticle, toTabIdentifier identifier: UUID? = nil) async throws {
        let moc = try coreDataStore.newBackgroundContext
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            let tab: CDArticleTab?
            if let identifier = identifier {
                let tabPredicate = NSPredicate(format: "identifier == %@", argumentArray: [identifier])
                tab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: tabPredicate, fetchLimit: 1, in: moc)?.first
            } else {
                let currentPredicate = NSPredicate(format: "isCurrent == YES")
                tab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: currentPredicate, fetchLimit: 1, in: moc)?.first
            }
            
            guard let tab else {
                throw CustomError.missingTab
            }
            
            let page = try self.pageForArticle(article, moc: moc)
            let articleTabItem = try self.newArticleTabItem(page: page, moc: moc)
            articleTabItem.tab = tab
            
            if let currentItems = tab.items as? NSMutableOrderedSet {
                currentItems.add(articleTabItem)
            } else {
                tab.items = NSOrderedSet(array: [articleTabItem])
            }
            
            try self.coreDataStore.saveIfNeeded(moc: moc)
        }
    }
    
    public func removeLastArticleFromTab(tabIdentifier: UUID) async throws {
        let moc = try coreDataStore.newBackgroundContext
        try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            let predicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
            
            guard let tab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
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
            moc.delete(lastItem)
            
            if items.count == 0,
               let tabIdentifer = tab.identifier {
                do {
                    let wasCurrent = tab.isCurrent
                    try self.deleteArticleTab(identifier: tabIdentifer, moc: moc)
                    
                    // If we deleted the current tab, find the next most recent tab to set as current
                    if wasCurrent {
                        let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
                        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "timestamp", ascending: false)]
                        if let nextTab = try moc.fetch(fetchRequest).first {
                            nextTab.isCurrent = true
                        }
                    }
                } catch {
                    guard let customError = error as? CustomError else {
                        throw error
                    }
                    
                    switch customError {
                    case .cannotDeleteLastTab:
                        break // this is fine
                    default:
                        throw customError
                    }
                }
            }
            
            try self.coreDataStore.saveIfNeeded(moc: moc)
        }
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
    
    private func tabsCount(moc: NSManagedObjectContext) throws -> Int {
        let fetchRequest = NSFetchRequest<CDArticleTab>(entityName: "CDArticleTab")
        return try moc.count(for: fetchRequest)
    }
    
    private func deleteArticleTab(identifier: UUID, moc: NSManagedObjectContext) throws {
        let tabsCount = try tabsCount(moc: moc)
        
        if tabsCount <= 1 {
            throw CustomError.cannotDeleteLastTab
        }
        
        let predicate = NSPredicate(format: "identifier == %@", argumentArray: [identifier])
        
        guard let articleTab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first else {
            throw CustomError.missingTab
        }
        
        if let items = articleTab.items {
            for item in items {
                guard let articleTabItem = item as? CDArticleTabItem else {
                    throw CustomError.unexpectedType
                }
                
                articleTabItem.tab = nil
                moc.delete(articleTabItem)
            }
        }
        
        moc.delete(articleTab)
    }
    
    public func currentTabIdentifier() async throws -> UUID {
        let moc = try coreDataStore.newBackgroundContext
        return try await moc.perform {
            let predicate = NSPredicate(format: "isCurrent == YES")
            guard let currentTab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: predicate, fetchLimit: 1, in: moc)?.first,
                  let identifier = currentTab.identifier else {
                throw CustomError.missingTab
            }
            return identifier
        }
    }
    
    private func setTabAsCurrent(tabIdentifier: UUID, moc: NSManagedObjectContext) throws {
        // First set all other tabs to not current
        let currentPredicate = NSPredicate(format: "isCurrent == YES")
        if let currentTab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: currentPredicate, fetchLimit: 1, in: moc)?.first {
            currentTab.isCurrent = false
        }
        
        // Then set the specified tab as current
        let tabPredicate = NSPredicate(format: "identifier == %@", argumentArray: [tabIdentifier])
        guard let tab = try self.coreDataStore.fetch(entityType: CDArticleTab.self, predicate: tabPredicate, fetchLimit: 1, in: moc)?.first else {
            throw CustomError.missingTab
        }
        
        tab.isCurrent = true
    }
    
    public func fetchAllArticleTabs() async throws -> [WMFArticleTab] {
        let moc = try coreDataStore.newBackgroundContext
        let databaseTabs = try await moc.perform { [weak self] in
            guard let self else { throw CustomError.missingSelf }
            
            guard let cdArticleTabs = try coreDataStore.fetch(entityType: CDArticleTab.self, predicate: nil, fetchLimit: nil, in: moc) else {
                throw CustomError.missingTab
            }
            
            var articleTabs: [WMFArticleTab] = []
            
            for cdTab in cdArticleTabs {
                guard let identifier = cdTab.identifier else {
                    throw CustomError.missingTabIdentifier
                }
                
                guard let timestamp = cdTab.timestamp else {
                    throw CustomError.missingTimestamp
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
                
                let articleTab = WMFArticleTab(identifier: identifier, timestamp: timestamp, isCurrent: cdTab.isCurrent, articles: articles)
                articleTabs.append(articleTab)
            }
            
            return articleTabs
        }
        
        return try await databaseTabsWithArticleSummaries(databaseTabs: databaseTabs)
    }
    
    private func databaseTabsWithArticleSummaries(databaseTabs: [WMFArticleTab]) async throws -> [WMFArticleTab] {
        return try await withThrowingTaskGroup(of: WMFArticleTab.self) { group in
            for tab in databaseTabs {
                guard let lastArticle = tab.articles.last else {
                    group.addTask {
                        return tab
                    }
                    continue
                }
                
                group.addTask {
                    do {
                        let articleSummary = try await self.articleSummaryDataController.fetchArticleSummary(project: lastArticle.project, title: lastArticle.title)
                        var updatedArticles = tab.articles
                        
                        let updatedArticle = WMFArticle(
                                title: lastArticle.title,
                                description: articleSummary.description,
                                summary: articleSummary.extract,
                                imageURL: articleSummary.thumbnailURL,
                                project: lastArticle.project
                            )
                        updatedArticles[updatedArticles.count - 1] = updatedArticle
                        
                        return WMFArticleTab(identifier: tab.identifier, timestamp: tab.timestamp, isCurrent: tab.isCurrent, articles: updatedArticles)
                    } catch {
                        print("Error fetching summary for article \(lastArticle.title): \(error)")
                        return tab
                    }
                }
            }
            
            var updatedTabs: [WMFArticleTab] = []
            for try await updatedTab in group {
                updatedTabs.append(updatedTab)
            }
            
            return updatedTabs
        }
    }
}
