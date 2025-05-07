import Foundation
import WMFData

#if DEBUG

public final class WMFMockArticleTabsDataController: WMFArticleTabsDataControlling {
    // MARK: - Properties
    
    private var tabs: [WMFArticleTabsDataController.WMFArticleTab] = []
    
    public init() {
        
    }
    
    // MARK: - WMFArticleTabsDataControlling
    
    public func tabsCount() async throws -> Int {
        return tabs.count
    }
    
    public func createArticleTab(initialArticle: WMFArticleTabsDataController.WMFArticle?, setAsCurrent: Bool = false) async throws -> UUID {
        let identifier = UUID()
        let timestamp = Date()
        
        // If setting as current, update all other tabs
        if setAsCurrent {
            for i in 0..<tabs.count {
                tabs[i] = WMFArticleTabsDataController.WMFArticleTab(
                    identifier: tabs[i].identifier,
                    timestamp: tabs[i].timestamp,
                    isCurrent: false,
                    articles: tabs[i].articles
                )
            }
        }
        
        let articles = initialArticle.map { [$0] } ?? []
        let newTab = WMFArticleTabsDataController.WMFArticleTab(
            identifier: identifier,
            timestamp: timestamp,
            isCurrent: setAsCurrent,
            articles: articles
        )
        
        tabs.append(newTab)
        return identifier
    }
    
    public func deleteArticleTab(identifier: UUID) async throws {
        guard tabs.count > 1 else {
            throw WMFArticleTabsDataController.CustomError.cannotDeleteLastTab
        }
        
        guard let index = tabs.firstIndex(where: { $0.identifier == identifier }) else {
            throw WMFArticleTabsDataController.CustomError.missingTab
        }
        
        let wasCurrent = tabs[index].isCurrent
        tabs.remove(at: index)
        
        // If we deleted the current tab, set the most recent tab as current
        if wasCurrent {
            tabs.sort { $0.timestamp > $1.timestamp }
            if let firstTab = tabs.first {
                tabs[0] = WMFArticleTabsDataController.WMFArticleTab(
                    identifier: firstTab.identifier,
                    timestamp: firstTab.timestamp,
                    isCurrent: true,
                    articles: firstTab.articles
                )
            }
        }
    }
    
    public func appendArticle(_ article: WMFArticleTabsDataController.WMFArticle, toTabIdentifier identifier: UUID? = nil) async throws {
        let targetIdentifier: UUID
        if let identifier = identifier {
            targetIdentifier = identifier
        } else if let currentTab = tabs.first(where: { $0.isCurrent }) {
            targetIdentifier = currentTab.identifier
        } else {
            throw WMFArticleTabsDataController.CustomError.missingTab
        }
        
        guard let index = tabs.firstIndex(where: { $0.identifier == targetIdentifier }) else {
            throw WMFArticleTabsDataController.CustomError.missingTab
        }
        
        var updatedArticles = tabs[index].articles
        updatedArticles.append(article)
        
        tabs[index] = WMFArticleTabsDataController.WMFArticleTab(
            identifier: tabs[index].identifier,
            timestamp: tabs[index].timestamp,
            isCurrent: tabs[index].isCurrent,
            articles: updatedArticles
        )
    }
    
    public func removeLastArticleFromTab(tabIdentifier: UUID) async throws {
        guard let index = tabs.firstIndex(where: { $0.identifier == tabIdentifier }) else {
            throw WMFArticleTabsDataController.CustomError.missingTab
        }
        
        guard !tabs[index].articles.isEmpty else {
            throw WMFArticleTabsDataController.CustomError.missingPage
        }
        
        var updatedArticles = tabs[index].articles
        updatedArticles.removeLast()
        
        tabs[index] = WMFArticleTabsDataController.WMFArticleTab(
            identifier: tabs[index].identifier,
            timestamp: tabs[index].timestamp,
            isCurrent: tabs[index].isCurrent,
            articles: updatedArticles
        )
    }
    
    public func fetchAllArticleTabs() async throws -> [WMFArticleTabsDataController.WMFArticleTab] {
        return tabs
    }

    public func populateWithInitialTabs() async throws {
        
        let enProject = WMFProject.wikipedia(WMFLanguage(languageCode: "en", languageVariantCode: nil))
        
        // Article data with kitten image URLs
        let kittenURL = "https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Six_weeks_old_cat_%28aka%29.jpg/330px-Six_weeks_old_cat_%28aka%29.jpg"
        let articleData: [(title: String, imageURL: String)] = [
            ("Cat", kittenURL),
            ("Dog", kittenURL),
            ("Elephant", kittenURL),
            ("Giraffe", kittenURL),
            ("Lion", kittenURL),
            ("Tiger", kittenURL),
            ("Penguin", kittenURL),
            ("Dolphin", kittenURL),
            ("Eagle", kittenURL),
            ("Shark", kittenURL)
        ]
        
        // Create 5 tabs
        for i in 0..<5 {
            // Create 10 articles for each tab
            var articles: [WMFArticleTabsDataController.WMFArticle] = []
            for (title, imageURL) in articleData {
                let article = WMFArticleTabsDataController.WMFArticle(
                    title: title,
                    description: "Description for \(title)",
                    summary: "Summary for \(title)",
                    imageURL: URL(string: imageURL),
                    project: enProject
                )
                articles.append(article)
            }
            
            // Create the tab with the articles
            let identifier = UUID()
            let timestamp = Date().addingTimeInterval(-Double(i * 60)) // Space out timestamps by 1 minute
            let isCurrent = i == 0 // First tab is current
            
            let tab = WMFArticleTabsDataController.WMFArticleTab(
                identifier: identifier,
                timestamp: timestamp,
                isCurrent: isCurrent,
                articles: articles
            )
            
            tabs.append(tab)
        }
    }
    
    public func currentTabIdentifier() async throws -> UUID {
        for tab in tabs {
            if tab.isCurrent {
                return tab.identifier
            }
        }
        
        assertionFailure("Shouldn't get here.")
        return UUID()
    }
}

#endif
