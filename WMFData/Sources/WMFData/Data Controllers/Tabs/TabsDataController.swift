import Foundation

public final class Tab: Equatable {
    public final class Article: Equatable {
        public let title: String
        public let project: WMFProject
        
        public static func == (lhs: Article, rhs: Article) -> Bool {
            return
                lhs.title == rhs.title &&
                lhs.project == rhs.project
        }
        
        public init(title: String, project: WMFProject) {
            self.title = title
            self.project = project
        }
    }
    
    let id: UUID = UUID()
    public private(set) var articles: [Article]
    public let dateCreated: Date
    
    public init(articles: [WMFData.Tab.Article]) {
        self.articles = articles
        self.dateCreated = Date()
    }
    
    public static func == (lhs: WMFData.Tab, rhs: WMFData.Tab) -> Bool {
        return lhs.articles == rhs.articles &&
            lhs.id == rhs.id
    }
    
    public func addArticle(_ article: Article) {
        articles.append(article)
    }
    
    func removeArticle(_ article: Article) {
        var indexToRemove: Int?
        for (index, reverseArticle) in articles.reversed().enumerated() {
            if reverseArticle == article {
                indexToRemove = articles.count - 1 - index
            }
        }
        
        if let indexToRemove,
           articles.count > indexToRemove {
            articles.remove(at: indexToRemove)
        }
    }
}

public final class TabsDataController {
   
    public static let shared = TabsDataController(tabs: [])
    
    public var currentTab: WMFData.Tab?
    
    public private(set) var tabs: [WMFData.Tab]
    
    init(tabs: [WMFData.Tab]) {
        self.tabs = tabs
    }
    
    public func addArticleToCurrentTab(article: WMFData.Tab.Article) {
        
        guard let currentTab else {
            let newTab = WMFData.Tab(articles: [article])
            addTab(tab: newTab)
            self.currentTab = newTab
            return
        }
        
        // if article is already top of current tab, do nothing
        if let topArticle = currentTab.articles.last,
              article == topArticle {
            return
        }
        
        currentTab.addArticle(article)
    }
    
    public func removeArticleFromCurrentTab(article: WMFData.Tab.Article) {
        guard let currentTab else {
            assertionFailure("No current tab!")
            return
        }
        
        remove(article: article, from: currentTab)
    }

    public func remove(article: WMFData.Tab.Article, from tab: WMFData.Tab) {
        tab.removeArticle(article)
        
        if tab.articles.count == 0 {
            removeTab(tab: tab)
        }
    }
    
    public func addTab(tab: WMFData.Tab) {
        tabs.append(tab)
    }
    
    public func removeTab(tab: WMFData.Tab) {
        tabs.removeAll { $0 == tab }
        
        if currentTab == tab {
            currentTab = nil
        }
    }
}
